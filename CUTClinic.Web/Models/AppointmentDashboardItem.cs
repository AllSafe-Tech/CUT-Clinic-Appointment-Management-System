
using System;
using System.Text.Json.Serialization;

namespace CUTClinic.Web.Models;

/// <summary>
/// Represents an appointment retrieved from Supabase, including
/// its service information and related student details.
/// </summary>
public sealed class AppointmentDashboardItem
{
    // Unique appointment identifier from the existing appointments table.
    [JsonPropertyName("appointment_id")]
    public Guid AppointmentId { get; set; }

    // UUID of the student associated with this appointment.
    [JsonPropertyName("student_id")]
    public Guid StudentId { get; set; }

    // Appointment date and time may be NULL before staff schedule it.
    [JsonPropertyName("appointment_date")]
    public DateOnly? AppointmentDate { get; set; }

    [JsonPropertyName("appointment_time")]
    public TimeOnly? AppointmentTime { get; set; }

    // Current appointment status, such as pending, approved,
    // rejected, cancelled or completed.
    [JsonPropertyName("status")]
    public string Status { get; set; } = "pending";

    // Optional notes associated with the appointment.
    [JsonPropertyName("notes")]
    public string? Notes { get; set; }

    // Human-readable service name stored as text in Supabase.
    [JsonPropertyName("service_name")]
    public string? ServiceName { get; set; }

    // UUID identifying the service in Supabase.
    // Nullable to handle existing appointments without a service ID.
    [JsonPropertyName("service_id")]
    public Guid? ServiceId { get; set; }

    // Timestamp showing when the appointment record was created.
    [JsonPropertyName("created_at")]
    public DateTimeOffset CreatedAt { get; set; }

    // Timestamp showing when the appointment record was last updated.
    [JsonPropertyName("updated_at")]
    public DateTimeOffset UpdatedAt { get; set; }

    // Related student information returned by the Supabase query.
    [JsonPropertyName("students")]
    public StudentSummary? Student { get; set; }
}

/// <summary>
/// Contains the student fields required by the staff website.
/// The data comes from the existing related students table.
/// </summary>
public sealed class StudentSummary
{
    [JsonPropertyName("first_name")]
    public string FirstName { get; set; } = string.Empty;

    [JsonPropertyName("last_name")]
    public string LastName { get; set; } = string.Empty;

    [JsonPropertyName("student_number")]
    public string StudentNumber { get; set; } = string.Empty;

    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("phone")]
    public string Phone { get; set; } = string.Empty;
}
