
using System;
using System.Linq;
using System.Threading.Tasks;
using CUTClinic.Web.Services;
using CUTClinic.Web.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CUTClinic.Web.Controllers;

/// <summary>
/// Loads the appointment dashboard and profile for authenticated
/// clinic staff.
/// </summary>
[Authorize(Roles = "Staff")]
public class HomeController : Controller
{
    private readonly SupabaseAppointmentService _appointmentService;

    /// <summary>
    /// ASP.NET Core injects the registered appointment service.
    /// </summary>
    public HomeController(
        SupabaseAppointmentService appointmentService)
    {
        _appointmentService = appointmentService;
    }

    /// <summary>
    /// Retrieves appointments and calculates dashboard statistics.
    /// No appointment records are modified by this action.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> Index()
    {
        // Read the Supabase access token saved during staff login.
        string? accessToken =
            User.FindFirst("supabase_access_token")?.Value;

        // Do not query Supabase without the staff access token.
        if (string.IsNullOrWhiteSpace(accessToken))
        {
            return Unauthorized();
        }

        // Reuse the existing service and its current Supabase queries.
        var appointments =
            await _appointmentService.GetAppointmentsAsync(
                accessToken,
                HttpContext.RequestAborted);

        // Compare status values without depending on letter casing.
        bool HasStatus(
            CUTClinic.Web.Models.AppointmentDashboardItem appointment,
            string expectedStatus)
        {
            return string.Equals(
                appointment.Status?.Trim(),
                expectedStatus,
                StringComparison.OrdinalIgnoreCase);
        }

        // A valid scheduled appointment must be approved and have
        // both a date and a time. Rejected/cancelled records are excluded.
        bool IsScheduled(
            CUTClinic.Web.Models.AppointmentDashboardItem appointment)
        {
            return HasStatus(appointment, "approved") &&
                   appointment.AppointmentDate.HasValue &&
                   appointment.AppointmentTime.HasValue;
        }

        // Match today's date without relying on a specific date property
        // type (DateOnly or DateTime).
        string today = DateTime.Today.ToString("yyyy-MM-dd");

        var model = new DashboardViewModel
        {
            // Keep the existing appointment table data.
            Appointments = appointments,

            // Count all records returned by the existing service.
            TotalRequests = appointments.Count,

            // Requests still waiting for staff action.
            PendingRequests = appointments.Count(appointment =>
                HasStatus(appointment, "pending")),

            // Approved appointments with an assigned date and time.
            ScheduledAppointments = appointments.Count(IsScheduled),

            // Appointments whose current status is completed.
            CompletedAppointments = appointments.Count(appointment =>
                HasStatus(appointment, "completed")),

            // Requests rejected by clinic staff.
            RejectedRequests = appointments.Count(appointment =>
                HasStatus(appointment, "rejected")),

            // Appointments cancelled by a student or staff member.
            CancelledAppointments = appointments.Count(appointment =>
                HasStatus(appointment, "cancelled") ||
                HasStatus(appointment, "canceled")),

            // Approved appointments scheduled for the current date.
            TodaysAppointments = appointments.Count(appointment =>
                IsScheduled(appointment) &&
                appointment.AppointmentDate!.Value
                    .ToString("yyyy-MM-dd") == today)
        };

        return View(model);
    }

    /// <summary>
    /// Displays the profile of the currently authenticated account.
    /// Profile information comes from claims established at login.
    /// </summary>
    [HttpGet]
    public IActionResult Profile()
    {
        // Read identity details from the authenticated claims.
        var model = new AdminProfileViewModel
        {
            FullName = User.Identity?.Name ?? "Name not available",

            Email = User.FindFirst(
                System.Security.Claims.ClaimTypes.Email)?.Value
                ?? "Email not available",

            Role = User.IsInRole("Admin")
                ? "Administrator"
                : User.IsInRole("Staff")
                    ? "Clinic Staff"
                    : "Unassigned",

            IsAuthenticated = User.Identity?.IsAuthenticated == true
        };

        return View(model);
    }
}
