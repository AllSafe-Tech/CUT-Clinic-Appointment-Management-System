
using System;
using System.Globalization;
using System.Net.Http;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using CUTClinic.Web.Services;
using Microsoft.AspNetCore.Mvc;

/// <summary>
/// Supplies the unread notification count to the shared website layout.
/// Keeping this logic in a component avoids placing database requests
/// directly inside the Razor layout.
/// </summary>
public sealed class StaffNotificationBellViewComponent : ViewComponent
{
    private readonly SupabaseStaffNotificationService _notificationService;

    public StaffNotificationBellViewComponent(
        SupabaseStaffNotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task<IViewComponentResult> InvokeAsync()
    {
        // Default to zero so a temporary notification failure does not
        // prevent the rest of the website from rendering.
        int unreadCount = 0;

        var user = HttpContext.User;

        // Only authenticated clinic staff should see this component.
        if (user.Identity?.IsAuthenticated != true ||
            !user.IsInRole("Staff"))
        {
            return View(unreadCount);
        }

        // The login process stores the numeric staff ID in this claim.
        string? staffIdValue =
            user.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (!long.TryParse(
                staffIdValue,
                NumberStyles.None,
                CultureInfo.InvariantCulture,
                out long staffId) ||
            staffId <= 0)
        {
            return View(unreadCount);
        }

        // Use the signed-in user's Supabase token so RLS stays active.
        string? accessToken =
            user.FindFirst("supabase_access_token")?.Value;

        if (string.IsNullOrWhiteSpace(accessToken))
        {
            return View(unreadCount);
        }

        try
        {
            var notifications =
                await _notificationService.GetNotificationsAsync(
                    staffId,
                    accessToken,
                    HttpContext.RequestAborted);

            // Count only notifications that have not been read.
            unreadCount = notifications.Count(notification =>
                !notification.IsRead);
        }
        catch (HttpRequestException)
        {
            // Keep the navigation usable if Supabase is temporarily down.
        }
        catch (InvalidOperationException)
        {
            // Missing configuration or an API error must not break the layout.
        }
        catch (UnauthorizedAccessException)
        {
            // Do not expose token or authorization details in the page.
        }

        return View(unreadCount);
    }
}
