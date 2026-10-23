
using System;
using System.Globalization;
using System.Net.Http;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CUTClinic.Web.Services;

namespace CUTClinic.Web.Controllers;

/// <summary>
/// Handles the staff notifications page and read-status actions.
/// Only authenticated clinic staff can access these actions.
/// </summary>
[Authorize(Roles = "Staff")]
public sealed class StaffNotificationsController : Controller
{
    private readonly SupabaseStaffNotificationService _notificationService;

    public StaffNotificationsController(
        SupabaseStaffNotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    /// <summary>
    /// Displays notifications belonging to the currently signed-in staff member.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> Index(
        CancellationToken cancellationToken)
    {
        // Obtain the numeric staff ID established during staff login.
        if (!TryGetStaffId(out long staffId))
        {
            return Forbid();
        }

        // The access token allows Supabase RLS to authorize this request.
        string? accessToken = User.FindFirst("supabase_access_token")?.Value;

        if (string.IsNullOrWhiteSpace(accessToken))
        {
            return Challenge();
        }

        try
        {
            var notifications =
                await _notificationService.GetNotificationsAsync(
                    staffId,
                    accessToken,
                    cancellationToken);

            // Pass the notifications directly to the strongly typed view.
            return View(notifications);
        }
        catch (HttpRequestException)
        {
            // Show a friendly error if Supabase cannot be reached or
            // returns an unsuccessful HTTP response.
            TempData["ErrorMessage"] =
                "Notifications could not be loaded. Please try again.";

            return View(
                new System.Collections.Generic
                    .List<CUTClinic.Web.Models.StaffNotificationItem>());
        }
        catch (InvalidOperationException)
        {
            TempData["ErrorMessage"] =
                "The notification service could not complete the request.";

            return View(
                new System.Collections.Generic
                    .List<CUTClinic.Web.Models.StaffNotificationItem>());
        }
    }

    /// <summary>
    /// Marks a notification as read, then returns to the notification list.
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> MarkAsRead(
        Guid id,
        CancellationToken cancellationToken)
    {
        if (!TryGetStaffId(out long staffId))
        {
            return Forbid();
        }

        string? accessToken = User.FindFirst("supabase_access_token")?.Value;

        if (string.IsNullOrWhiteSpace(accessToken))
        {
            return Challenge();
        }

        try
        {
            await _notificationService.MarkAsReadAsync(
                id,
                staffId,
                accessToken,
                cancellationToken);

            TempData["SuccessMessage"] = "Notification marked as read.";
        }
        catch (HttpRequestException)
        {
            TempData["ErrorMessage"] =
                "The notification could not be updated. Please try again.";
        }
        catch (InvalidOperationException)
        {
            TempData["ErrorMessage"] =
                "The notification was not updated. Check its status and try again.";
        }
        catch (ArgumentException)
        {
            TempData["ErrorMessage"] =
                "The notification ID is invalid.";
        }

        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Reads the staff ID from the protected authentication claims.
    /// The ID is numeric and is not the Supabase Auth UUID.
    /// </summary>
    private bool TryGetStaffId(out long staffId)
    {
        string? staffIdClaim =
            User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        return long.TryParse(
            staffIdClaim,
            NumberStyles.None,
            CultureInfo.InvariantCulture,
            out staffId)
            && staffId > 0;
    }
}
