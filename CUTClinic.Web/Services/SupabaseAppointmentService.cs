
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;
using CUTClinic.Web.Models;
using Microsoft.Extensions.Configuration;

namespace CUTClinic.Web.Services;

/// <summary>
/// Retrieves and updates appointments through the Supabase REST API.
///
/// Requests use the authenticated staff member's access token.
/// Supabase Row Level Security remains responsible for access control.
/// This service must never use a service-role key.
/// </summary>
public sealed class SupabaseAppointmentService
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    // Use consistent JSON settings for all Supabase responses.
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public SupabaseAppointmentService(
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    /// <summary>
    /// Retrieves all appointments and their related student information.
    /// Includes the service name and service UUID.
    /// Results are ordered from newest to oldest.
    /// </summary>
    public async Task<List<AppointmentDashboardItem>> GetAppointmentsAsync(
        string accessToken,
        CancellationToken cancellationToken = default)
    {
        ValidateAccessToken(accessToken);

        // Select the existing service_name and service_id columns.
        string requestUrl = GetSupabaseUrl() +
            "/rest/v1/appointments" +
            "?select=appointment_id,student_id,appointment_date," +
            "appointment_time,status,notes,service_name,service_id," +
            "created_at,updated_at," +
            "students(first_name,last_name,student_number,email,phone)" +
            "&order=created_at.desc";

        using HttpRequestMessage request =
            new(HttpMethod.Get, requestUrl);

        AddAuthenticationHeaders(request, accessToken);

        HttpClient client = _httpClientFactory.CreateClient();

        using HttpResponseMessage response = await client.SendAsync(
            request,
            cancellationToken);

        // Surface Supabase errors instead of silently returning no records.
        response.EnsureSuccessStatusCode();

        await using Stream responseStream =
            await response.Content.ReadAsStreamAsync(cancellationToken);

        List<AppointmentDashboardItem>? appointments =
            await JsonSerializer.DeserializeAsync<List<AppointmentDashboardItem>>(
                responseStream,
                JsonOptions,
                cancellationToken);

        return appointments ?? new List<AppointmentDashboardItem>();
    }

    /// <summary>
    /// Retrieves every appointment belonging to a specific student.
    /// Includes current and historical appointment statuses.
    /// </summary>
    public async Task<List<AppointmentDashboardItem>>
        GetStudentAppointmentHistoryAsync(
            Guid studentId,
            string accessToken,
            CancellationToken cancellationToken = default)
    {
        ValidateAccessToken(accessToken);

        if (studentId == Guid.Empty)
        {
            throw new ArgumentException(
                "A valid student ID is required.",
                nameof(studentId));
        }

        // Retrieve service information and student details while
        // filtering against the existing student_id UUID column.
        string requestUrl = GetSupabaseUrl() +
            "/rest/v1/appointments" +
            "?select=appointment_id,student_id,appointment_date," +
            "appointment_time,status,notes,service_name,service_id," +
            "created_at,updated_at," +
            "students(first_name,last_name,student_number,email,phone)" +
            $"&student_id=eq.{studentId:D}" +
            "&order=created_at.desc";

        using HttpRequestMessage request =
            new(HttpMethod.Get, requestUrl);

        AddAuthenticationHeaders(request, accessToken);

        HttpClient client = _httpClientFactory.CreateClient();

        using HttpResponseMessage response = await client.SendAsync(
            request,
            cancellationToken);

        response.EnsureSuccessStatusCode();

        await using Stream responseStream =
            await response.Content.ReadAsStreamAsync(cancellationToken);

        List<AppointmentDashboardItem>? appointments =
            await JsonSerializer.DeserializeAsync<List<AppointmentDashboardItem>>(
                responseStream,
                JsonOptions,
                cancellationToken);

        return appointments ?? new List<AppointmentDashboardItem>();
    }

    /// <summary>
    /// Checks whether another approved appointment already occupies
    /// the requested date and time.
    ///
    /// The appointment being edited is excluded from the comparison.
    /// This application-level check does not prevent simultaneous
    /// requests from passing the check at the same time.
    /// </summary>
    public async Task<bool> IsAppointmentSlotTakenAsync(
        DateOnly appointmentDate,
        TimeOnly appointmentTime,
        Guid excludedAppointmentId,
        string accessToken,
        CancellationToken cancellationToken = default)
    {
        ValidateAccessToken(accessToken);

        List<AppointmentDashboardItem> appointments =
            await GetAppointmentsAsync(accessToken, cancellationToken);

        return appointments.Any(appointment =>
            appointment.AppointmentId != excludedAppointmentId &&

            string.Equals(
                appointment.Status,
                "approved",
                StringComparison.OrdinalIgnoreCase) &&

            appointment.AppointmentDate is DateOnly existingDate &&
            appointment.AppointmentTime is TimeOnly existingTime &&

            existingDate == appointmentDate &&
            existingTime == appointmentTime);
    }

    /// <summary>
    /// Marks overdue approved appointments as completed.
    ///
    /// This runs only when called by the application, for example
    /// when staff open a dashboard or details page. It is not a
    /// continuously running background task.
    /// </summary>
    public async Task CompleteOverdueAppointmentsAsync(
        string accessToken,
        CancellationToken cancellationToken = default)
    {
        ValidateAccessToken(accessToken);

        List<AppointmentDashboardItem> appointments =
            await GetAppointmentsAsync(accessToken, cancellationToken);

        // Calculate the current South African time (UTC+2).
        DateTime southAfricanNow = DateTimeOffset.UtcNow
            .ToOffset(TimeSpan.FromHours(2))
            .DateTime;

        foreach (AppointmentDashboardItem appointment in appointments)
        {
            cancellationToken.ThrowIfCancellationRequested();

            // Only approved appointments should be completed automatically.
            if (!string.Equals(
                    appointment.Status,
                    "approved",
                    StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            // Do not complete appointments without an assigned date and time.
            if (appointment.AppointmentDate is not DateOnly appointmentDate ||
                appointment.AppointmentTime is not TimeOnly appointmentTime)
            {
                continue;
            }

            // Combine the scheduled date and time for comparison.
            DateTime scheduledDateTime = appointmentDate.ToDateTime(
                appointmentTime,
                DateTimeKind.Unspecified);

            // Complete the appointment if its scheduled time has passed.
            if (scheduledDateTime <= southAfricanNow)
            {
                await CompleteAppointmentAsync(
                    appointment.AppointmentId,
                    accessToken,
                    cancellationToken);
            }
        }
    }

    /// <summary>
    /// Approves a pending request and assigns the date and time
    /// selected by clinic staff.
    /// </summary>
    public Task UpdateAppointmentScheduleAsync(
        Guid appointmentId,
        DateOnly appointmentDate,
        TimeOnly appointmentTime,
        string accessToken,
        CancellationToken cancellationToken = default)
    {
        // Update the status and assigned schedule together.
        var changes = new Dictionary<string, object?>
        {
            ["status"] = "approved",
            ["appointment_date"] = appointmentDate.ToString("yyyy-MM-dd"),
            ["appointment_time"] = appointmentTime.ToString("HH:mm:ss")
        };

        return UpdateAppointmentAsync(
            appointmentId,
            changes,
            accessToken,
            cancellationToken);
    }

    /// <summary>
    /// Rejects a pending appointment without deleting its history.
    /// </summary>
    public Task RejectAppointmentAsync(
        Guid appointmentId,
        string accessToken,
        CancellationToken cancellationToken = default)
    {
        var changes = new Dictionary<string, object?>
        {
            ["status"] = "rejected"
        };

        return UpdateAppointmentAsync(
            appointmentId,
            changes,
            accessToken,
            cancellationToken);
    }

    /// <summary>
    /// Marks an appointment as completed while preserving its record.
    /// </summary>
    public Task CompleteAppointmentAsync(
        Guid appointmentId,
        string accessToken,
        CancellationToken cancellationToken = default)
    {
        var changes = new Dictionary<string, object?>
        {
            ["status"] = "completed"
        };

        return UpdateAppointmentAsync(
            appointmentId,
            changes,
            accessToken,
            cancellationToken);
    }

    /// <summary>
    /// Sends a partial update to Supabase and checks that a record
    /// was actually returned after the update.
    /// </summary>
    private async Task UpdateAppointmentAsync(
        Guid appointmentId,
        Dictionary<string, object?> changes,
        string accessToken,
        CancellationToken cancellationToken)
    {
        ValidateAccessToken(accessToken);

        if (appointmentId == Guid.Empty)
        {
            throw new ArgumentException(
                "A valid appointment ID is required.",
                nameof(appointmentId));
        }

        string requestUrl = GetSupabaseUrl() +
            "/rest/v1/appointments" +
            $"?appointment_id=eq.{appointmentId:D}" +
            "&select=appointment_id";

        using HttpRequestMessage request =
            new(HttpMethod.Patch, requestUrl);

        AddAuthenticationHeaders(request, accessToken);

        // Ask Supabase to return the updated appointment.
        request.Headers.TryAddWithoutValidation(
            "Prefer",
            "return=representation");

        request.Content = JsonContent.Create(changes);

        HttpClient client = _httpClientFactory.CreateClient();

        using HttpResponseMessage response = await client.SendAsync(
            request,
            cancellationToken);

        response.EnsureSuccessStatusCode();

        await using Stream responseStream =
            await response.Content.ReadAsStreamAsync(cancellationToken);

        List<AppointmentUpdateResult>? updatedAppointments =
            await JsonSerializer.DeserializeAsync<List<AppointmentUpdateResult>>(
                responseStream,
                JsonOptions,
                cancellationToken);

        // An empty response can mean no matching row was updated,
        // including when the current user's RLS permissions deny access.
        if (updatedAppointments is null || updatedAppointments.Count == 0)
        {
            throw new InvalidOperationException(
                "The appointment was not updated. Check that it exists " +
                "and that the authenticated staff member has permission.");
        }
    }

    /// <summary>
    /// Adds the Supabase publishable key and the authenticated
    /// staff member's access token to the request.
    /// </summary>
    private void AddAuthenticationHeaders(
        HttpRequestMessage request,
        string accessToken)
    {
        string? publishableKey =
            _configuration["Supabase:PublishableKey"];

        if (string.IsNullOrWhiteSpace(publishableKey))
        {
            throw new InvalidOperationException(
                "Supabase:PublishableKey is missing from configuration.");
        }

        request.Headers.Add("apikey", publishableKey);

        // Preserve RLS by using the signed-in staff member's token.
        request.Headers.Authorization =
            new AuthenticationHeaderValue("Bearer", accessToken);
    }

    /// <summary>
    /// Reads and validates the configured Supabase project URL.
    /// </summary>
    private string GetSupabaseUrl()
    {
        string? supabaseUrl = _configuration["Supabase:Url"];

        if (string.IsNullOrWhiteSpace(supabaseUrl))
        {
            throw new InvalidOperationException(
                "Supabase:Url is missing from configuration.");
        }

        return supabaseUrl.TrimEnd('/');
    }

    /// <summary>
    /// Rejects missing access tokens before database requests are sent.
    /// </summary>
    private static void ValidateAccessToken(string accessToken)
    {
        if (string.IsNullOrWhiteSpace(accessToken))
        {
            throw new UnauthorizedAccessException(
                "A valid staff access token is required.");
        }
    }

    /// <summary>
    /// Maps the appointment ID returned by a successful Supabase update.
    /// </summary>
    private sealed class AppointmentUpdateResult
    {
        [JsonPropertyName("appointment_id")]
        public Guid AppointmentId { get; set; }
    }
}
