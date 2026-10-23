
using System;
using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using CUTClinic.Web.Models;
using CUTClinic.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace CUTClinic.Web.Controllers
{
    // Only authenticated users with the Staff role can manage appointments.
    [Authorize(Roles = "Staff")]
    public class AppointmentRequestsController : Controller
    {
        private readonly SupabaseAppointmentService _appointmentService;
        private readonly GmailEmailService _emailService;
        private readonly ILogger<AppointmentRequestsController> _logger;

        // Dependencies are provided through ASP.NET Core dependency injection.
        public AppointmentRequestsController(
            SupabaseAppointmentService appointmentService,
            GmailEmailService emailService,
            ILogger<AppointmentRequestsController> logger)
        {
            _appointmentService = appointmentService;
            _emailService = emailService;
            _logger = logger;
        }

        // GET: /AppointmentRequests
        // Displays appointment requests and existing appointments.
        public async Task<IActionResult> Index(
            CancellationToken cancellationToken)
        {
            string? accessToken = GetStaffAccessToken();

            if (string.IsNullOrWhiteSpace(accessToken))
            {
                return Unauthorized();
            }

            try
            {
                // Automatically complete appointments whose assigned
                // date and time have passed before showing the dashboard.
                await _appointmentService.CompleteOverdueAppointmentsAsync(
                    accessToken,
                    cancellationToken);

                var appointments =
                    await _appointmentService.GetAppointmentsAsync(
                        accessToken,
                        cancellationToken);

                return View(appointments);
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(
                    ex,
                    "Unable to load appointments from Supabase.");

                TempData["Error"] =
                    "Appointments could not be loaded. Please try again.";

                return View(Array.Empty<AppointmentDashboardItem>());
            }
        }

        // GET: /AppointmentRequests/Details/{id}
        // Shows a selected appointment and the student's appointment history.
        public async Task<IActionResult> Details(
            Guid id,
            CancellationToken cancellationToken)
        {
            if (id == Guid.Empty)
            {
                return BadRequest();
            }

            string? accessToken = GetStaffAccessToken();

            if (string.IsNullOrWhiteSpace(accessToken))
            {
                return Unauthorized();
            }

            try
            {
                // Refresh overdue appointment statuses before loading details.
                await _appointmentService.CompleteOverdueAppointmentsAsync(
                    accessToken,
                    cancellationToken);

                var appointment =
                    await FindAppointmentAsync(id, accessToken, cancellationToken);

                if (appointment == null)
                {
                    return NotFound();
                }

                var history =
                    await _appointmentService.GetStudentAppointmentHistoryAsync(
                        appointment.StudentId,
                        accessToken,
                        cancellationToken);

                // Put the selected appointment first in the history list.
                var orderedHistory = history
                    .OrderByDescending(item => item.AppointmentId == id)
                    .ThenByDescending(item => item.CreatedAt)
                    .ToList();

                var model = new StudentAppointmentDetailsViewModel
                {
                    Appointment = appointment,
                    AppointmentHistory = orderedHistory
                };

                return View(model);
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(
                    ex,
                    "Unable to load appointment details for {AppointmentId}.",
                    id);

                TempData["Error"] =
                    "Appointment details could not be loaded.";

                return RedirectToAction(nameof(Index));
            }
        }

        // POST: /AppointmentRequests/Schedule/{id}
        // Approves a pending request and assigns its first appointment time.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Schedule(
            Guid id,
            DateOnly appointmentDate,
            TimeOnly appointmentTime,
            CancellationToken cancellationToken)
        {
            if (id == Guid.Empty)
            {
                return BadRequest();
            }

            string? accessToken = GetStaffAccessToken();

            if (string.IsNullOrWhiteSpace(accessToken))
            {
                return Unauthorized();
            }

            // Use South African local time (SAST, UTC+2).
            DateTime southAfricanNow = DateTimeOffset.UtcNow
                .ToOffset(TimeSpan.FromHours(2))
                .DateTime;

            // Combine the date and time to validate the actual appointment time.
            DateTime selectedDateTime = appointmentDate.ToDateTime(
                appointmentTime,
                DateTimeKind.Unspecified);

            // Reject past dates and earlier times on today's date.
            if (selectedDateTime <= southAfricanNow)
            {
                TempData["Error"] =
                    "The appointment date and time must be in the future.";

                return RedirectToAction(nameof(Details), new { id });
            }

            try
            {
                var appointment =
                    await FindAppointmentAsync(id, accessToken, cancellationToken);

                if (appointment == null)
                {
                    return NotFound();
                }

                // Only pending requests can be approved through this action.
                // Approved appointments use the separate Reschedule action.
                if (!string.Equals(
                    appointment.Status,
                    "pending",
                    StringComparison.OrdinalIgnoreCase))
                {
                    TempData["Error"] =
                        "Only pending appointment requests can be approved here.";

                    return RedirectToAction(nameof(Details), new { id });
                }

                // Check whether another approved appointment occupies this slot.
                bool slotTaken =
                    await _appointmentService.IsAppointmentSlotTakenAsync(
                        appointmentDate,
                        appointmentTime,
                        id,
                        accessToken,
                        cancellationToken);

                if (slotTaken)
                {
                    TempData["Error"] =
                        "That date and time are already assigned to another " +
                        "approved appointment. Please choose another slot.";

                    return RedirectToAction(nameof(Details), new { id });
                }

                await _appointmentService.UpdateAppointmentScheduleAsync(
                    id,
                    appointmentDate,
                    appointmentTime,
                    accessToken,
                    cancellationToken);

                // Reload the appointment so the email uses the latest details.
                appointment =
                    await FindAppointmentAsync(id, accessToken, cancellationToken);

                if (appointment?.Student?.Email is not string email ||
                    string.IsNullOrWhiteSpace(email))
                {
                    TempData["Success"] =
                        "Appointment approved and scheduled. " +
                        "No student email address was available.";

                    return RedirectToAction(nameof(Details), new { id });
                }

                try
                {
                    string subject = "CUT Clinic Appointment Approved";

                    string body =
                        $"Your CUT Clinic appointment has been approved.\n\n" +
                        $"Service: {appointment.ServiceName}\n" +
                        $"Date: {appointmentDate:dd MMMM yyyy}\n" +
                        $"Time: {appointmentTime:HH:mm}\n\n" +
                        "Please contact the clinic if you need assistance.";

                    await _emailService.SendEmailAsync(
                        email,
                        subject,
                        body);

                    TempData["Success"] =
                        "Appointment approved and scheduled. " +
                        "The student email was accepted for sending.";
                }
                catch (Exception emailException)
                {
                    // The appointment remains approved if email delivery fails.
                    _logger.LogError(
                        emailException,
                        "Approval email failed for appointment {AppointmentId}.",
                        id);

                    TempData["Warning"] =
                        "Appointment approved, but the email could not be sent.";
                }

                return RedirectToAction(nameof(Details), new { id });
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(
                    ex,
                    "Supabase request failed while scheduling {AppointmentId}.",
                    id);

                TempData["Error"] =
                    "The appointment could not be scheduled. Please try again.";

                return RedirectToAction(nameof(Details), new { id });
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(
                    ex,
                    "Appointment scheduling failed for {AppointmentId}.",
                    id);

                TempData["Error"] = ex.Message;

                return RedirectToAction(nameof(Details), new { id });
            }
        }

        // POST: /AppointmentRequests/Reschedule/{id}
        // Allows staff to change the date/time of an approved appointment.
        // The service keeps the appointment status as "approved".
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Reschedule(
            Guid id,
            DateOnly appointmentDate,
            TimeOnly appointmentTime,
            CancellationToken cancellationToken)
        {
            if (id == Guid.Empty)
            {
                return BadRequest();
            }

            string? accessToken = GetStaffAccessToken();

            if (string.IsNullOrWhiteSpace(accessToken))
            {
                return Unauthorized();
            }

            DateTime southAfricanNow = DateTimeOffset.UtcNow
                .ToOffset(TimeSpan.FromHours(2))
                .DateTime;

            DateTime selectedDateTime = appointmentDate.ToDateTime(
                appointmentTime,
                DateTimeKind.Unspecified);

            if (selectedDateTime <= southAfricanNow)
            {
                TempData["Error"] =
                    "The new appointment date and time must be in the future.";

                return RedirectToAction(nameof(Details), new { id });
            }

            try
            {
                var appointment =
                    await FindAppointmentAsync(id, accessToken, cancellationToken);

                if (appointment == null)
                {
                    return NotFound();
                }

                if (!string.Equals(
                    appointment.Status,
                    "approved",
                    StringComparison.OrdinalIgnoreCase))
                {
                    TempData["Error"] =
                        "Only approved appointments can be rescheduled.";

                    return RedirectToAction(nameof(Details), new { id });
                }

                bool slotTaken =
                    await _appointmentService.IsAppointmentSlotTakenAsync(
                        appointmentDate,
                        appointmentTime,
                        id,
                        accessToken,
                        cancellationToken);

                if (slotTaken)
                {
                    TempData["Error"] =
                        "That date and time are already assigned to another " +
                        "approved appointment. Please choose another slot.";

                    return RedirectToAction(nameof(Details), new { id });
                }

                // The service updates the date/time and retains "approved".
                await _appointmentService.UpdateAppointmentScheduleAsync(
                    id,
                    appointmentDate,
                    appointmentTime,
                    accessToken,
                    cancellationToken);

                // Reload the appointment to retrieve the student's latest details.
                appointment =
                    await FindAppointmentAsync(id, accessToken, cancellationToken);

                if (appointment?.Student?.Email is not string email ||
                    string.IsNullOrWhiteSpace(email))
                {
                    TempData["Success"] =
                        "Appointment rescheduled, but no student email was available.";

                    return RedirectToAction(nameof(Details), new { id });
                }

                try
                {
                    string subject = "CUT Clinic Appointment Rescheduled";

                    string body =
                        "Your CUT Clinic appointment has been rescheduled.\n\n" +
                        $"Service: {appointment.ServiceName}\n" +
                        $"New date: {appointmentDate:dd MMMM yyyy}\n" +
                        $"New time: {appointmentTime:HH:mm}\n\n" +
                        "Please use the updated date and time. " +
                        "Contact the clinic if you need assistance.";

                    await _emailService.SendEmailAsync(
                        email,
                        subject,
                        body);

                    TempData["Success"] =
                        "Appointment rescheduled. The student email was accepted for sending.";
                }
                catch (Exception emailException)
                {
                    _logger.LogError(
                        emailException,
                        "Rescheduling email failed for appointment {AppointmentId}.",
                        id);

                    TempData["Warning"] =
                        "Appointment rescheduled, but the email could not be sent.";
                }

                return RedirectToAction(nameof(Details), new { id });
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(
                    ex,
                    "Supabase request failed while rescheduling {AppointmentId}.",
                    id);

                TempData["Error"] =
                    "The appointment could not be rescheduled.";

                return RedirectToAction(nameof(Details), new { id });
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(
                    ex,
                    "Appointment rescheduling failed for {AppointmentId}.",
                    id);

                TempData["Error"] = ex.Message;

                return RedirectToAction(nameof(Details), new { id });
            }
        }

        // POST: /AppointmentRequests/Reject/{id}
        // Rejects a pending request only.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Reject(
            Guid id,
            CancellationToken cancellationToken)
        {
            if (id == Guid.Empty)
            {
                return BadRequest();
            }

            string? accessToken = GetStaffAccessToken();

            if (string.IsNullOrWhiteSpace(accessToken))
            {
                return Unauthorized();
            }

            try
            {
                var appointment =
                    await FindAppointmentAsync(id, accessToken, cancellationToken);

                if (appointment == null)
                {
                    return NotFound();
                }

                if (!string.Equals(
                    appointment.Status,
                    "pending",
                    StringComparison.OrdinalIgnoreCase))
                {
                    TempData["Error"] =
                        "Only pending requests can be rejected.";

                    return RedirectToAction(nameof(Details), new { id });
                }

                await _appointmentService.RejectAppointmentAsync(
                    id,
                    accessToken,
                    cancellationToken);

                TempData["Success"] = "Appointment request rejected.";

                return RedirectToAction(nameof(Details), new { id });
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(
                    ex,
                    "Could not reject appointment {AppointmentId}.",
                    id);

                TempData["Error"] =
                    "The appointment request could not be rejected.";

                return RedirectToAction(nameof(Details), new { id });
            }
        }

        // POST: /AppointmentRequests/Complete/{id}
        // Retains the existing manual completion action.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Complete(
            Guid id,
            CancellationToken cancellationToken)
        {
            if (id == Guid.Empty)
            {
                return BadRequest();
            }

            string? accessToken = GetStaffAccessToken();

            if (string.IsNullOrWhiteSpace(accessToken))
            {
                return Unauthorized();
            }

            try
            {
                var appointment =
                    await FindAppointmentAsync(id, accessToken, cancellationToken);

                if (appointment == null)
                {
                    return NotFound();
                }

                if (!string.Equals(
                    appointment.Status,
                    "approved",
                    StringComparison.OrdinalIgnoreCase))
                {
                    TempData["Error"] =
                        "Only approved appointments can be completed.";

                    return RedirectToAction(nameof(Details), new { id });
                }

                await _appointmentService.CompleteAppointmentAsync(
                    id,
                    accessToken,
                    cancellationToken);

                TempData["Success"] = "Appointment marked as completed.";

                return RedirectToAction(nameof(Details), new { id });
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(
                    ex,
                    "Could not complete appointment {AppointmentId}.",
                    id);

                TempData["Error"] =
                    "The appointment could not be marked as completed.";

                return RedirectToAction(nameof(Details), new { id });
            }
        }

        // Retrieves the signed-in staff member's Supabase access token.
        private string? GetStaffAccessToken()
        {
            return User.FindFirst("supabase_access_token")?.Value;
        }

        // Finds an appointment using the existing Supabase service.
        private async Task<AppointmentDashboardItem?> FindAppointmentAsync(
            Guid id,
            string accessToken,
            CancellationToken cancellationToken)
        {
            var appointments =
                await _appointmentService.GetAppointmentsAsync(
                    accessToken,
                    cancellationToken);

            return appointments.FirstOrDefault(
                item => item.AppointmentId == id);
        }
    }
}
