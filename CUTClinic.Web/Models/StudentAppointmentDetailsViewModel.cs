
using System.Collections.Generic;

namespace CUTClinic.Web.Models;

/// <summary>
/// Combines the selected appointment with the student's appointment history.
/// This is a view model only; it does not create or modify database tables.
/// </summary>
public sealed class StudentAppointmentDetailsViewModel
{
    /// <summary>
    /// The appointment currently being viewed or managed by clinic staff.
    /// </summary>
    public AppointmentDashboardItem Appointment { get; set; } = new();

    /// <summary>
    /// All appointments retrieved for the same student, subject to Supabase RLS.
    /// Includes completed and other historical statuses when available.
    /// </summary>
    public List<AppointmentDashboardItem> AppointmentHistory { get; set; } = new();
}
