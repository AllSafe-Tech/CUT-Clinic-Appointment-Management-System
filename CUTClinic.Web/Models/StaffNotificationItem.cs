
using System.Text.Json.Serialization;

namespace CUTClinic.Web.Models;

/// <summary>
/// Represents one in-app notification displayed to clinic staff.
/// Property names are explicitly mapped to the existing Supabase
/// staff_notifications table columns.
/// </summary>
public sealed class StaffNotificationItem
{
    // Unique ID for this notification.
    [JsonPropertyName("notification_id")]
    public Guid NotificationId { get; set; }

    // ID of the staff member who receives this notification.
    [JsonPropertyName("staff_id")]
    public long StaffId { get; set; }

    // Appointment associated with the alert, if available.
    [JsonPropertyName("appointment_id")]
    public Guid? AppointmentId { get; set; }

    // Identifies the event that generated the notification.
    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    // Message displayed to the staff member.
    [JsonPropertyName("message")]
    public string Message { get; set; } = string.Empty;

    // False means unread; true means the notification was read.
    [JsonPropertyName("is_read")]
    public bool IsRead { get; set; }

    // Time the database created the notification.
    [JsonPropertyName("created_at")]
    public DateTimeOffset CreatedAt { get; set; }
}
