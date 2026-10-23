
using CUTClinic.Web.Models;
using System.Collections.Generic;

namespace CUTClinic.Web.ViewModels;

/// <summary>
/// Holds the summary counts and appointment records
/// displayed on the clinic staff dashboard.
/// </summary>
public sealed class DashboardViewModel
{
    /// <summary>
    /// Total number of appointment records retrieved from Supabase.
    /// </summary>
    public int TotalRequests { get; set; }

    /// <summary>
    /// Number of requests awaiting clinic staff action.
    /// </summary>
    public int PendingRequests { get; set; }

    /// <summary>
    /// Number of approved appointments with a date and time assigned.
    /// </summary>
    public int ScheduledAppointments { get; set; }

    /// <summary>
    /// Number of appointments marked as completed.
    /// </summary>
    public int CompletedAppointments { get; set; }

    /// <summary>
    /// Number of requests that were rejected.
    /// </summary>
    public int RejectedRequests { get; set; }

    /// <summary>
    /// Number of appointments that were cancelled.
    /// </summary>
    public int CancelledAppointments { get; set; }

    /// <summary>
    /// Number of approved appointments scheduled for today.
    /// </summary>
    public int TodaysAppointments { get; set; }

    /// <summary>
    /// Appointment records displayed in the dashboard table.
    /// The collection starts empty until data is loaded.
    /// </summary>
    public List<AppointmentDashboardItem> Appointments { get; set; }
        = new();
}
