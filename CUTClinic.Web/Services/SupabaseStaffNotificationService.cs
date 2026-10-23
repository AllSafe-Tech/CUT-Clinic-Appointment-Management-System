
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using CUTClinic.Web.Models;

namespace CUTClinic.Web.Services;

/// <summary>
/// Reads and updates staff in-app notifications through the Supabase REST API.
/// All requests use the signed-in staff member's access token so Supabase RLS
/// continues to enforce access permissions.
/// </summary>
public sealed class SupabaseStaffNotificationService
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    // Use consistent JSON deserialization settings for API responses.
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public SupabaseStaffNotificationService(
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    /// <summary>
    /// Retrieves notifications belonging to the specified staff member.
    /// Supabase RLS must still authorize the signed-in user.
    /// </summary>
    public async Task<List<StaffNotificationItem>> GetNotificationsAsync(
        long staffId,
        string accessToken,
        CancellationToken cancellationToken = default)
    {
        ValidateRequest(staffId, accessToken);

        // Request only the columns defined in the existing table.
        string requestUrl = GetSupabaseUrl() +
            "/rest/v1/staff_notifications" +
            $"?staff_id=eq.{staffId}" +
            "&select=notification_id,staff_id,appointment_id,type," +
            "message,is_read,created_at" +
            "&order=created_at.desc";

        using HttpRequestMessage request =
            new(HttpMethod.Get, requestUrl);

        AddAuthenticationHeaders(request, accessToken);

        HttpClient client = _httpClientFactory.CreateClient();

        using HttpResponseMessage response = await client.SendAsync(
            request,
            cancellationToken);

        // Surface API errors instead of silently returning an empty list.
        response.EnsureSuccessStatusCode();

        await using Stream responseStream =
            await response.Content.ReadAsStreamAsync(cancellationToken);

        List<StaffNotificationItem>? notifications =
            await JsonSerializer.DeserializeAsync<List<StaffNotificationItem>>(
                responseStream,
                JsonOptions,
                cancellationToken);

        return notifications ?? new List<StaffNotificationItem>();
    }

    /// <summary>
    /// Marks one notification as read.
    /// Both notification ID and staff ID are included in the filter.
    /// RLS remains the final authority on whether the update is allowed.
    /// </summary>
    public async Task MarkAsReadAsync(
        Guid notificationId,
        long staffId,
        string accessToken,
        CancellationToken cancellationToken = default)
    {
        ValidateRequest(staffId, accessToken);

        if (notificationId == Guid.Empty)
        {
            throw new ArgumentException(
                "A valid notification ID is required.",
                nameof(notificationId));
        }

        string requestUrl = GetSupabaseUrl() +
            "/rest/v1/staff_notifications" +
            $"?notification_id=eq.{notificationId:D}" +
            $"&staff_id=eq.{staffId}" +
            "&select=notification_id";

        using HttpRequestMessage request =
            new(HttpMethod.Patch, requestUrl);

        AddAuthenticationHeaders(request, accessToken);

        // Request the updated row so we can detect an empty update result.
        request.Headers.TryAddWithoutValidation(
            "Prefer",
            "return=representation");

        // Only the read flag is changed; all other notification data is kept.
        request.Content = JsonContent.Create(new { is_read = true });

        HttpClient client = _httpClientFactory.CreateClient();

        using HttpResponseMessage response = await client.SendAsync(
            request,
            cancellationToken);

        response.EnsureSuccessStatusCode();

        // Supabase returns an array when return=representation is requested.
        using JsonDocument result = await JsonDocument.ParseAsync(
            await response.Content.ReadAsStreamAsync(cancellationToken),
            cancellationToken: cancellationToken);

        if (result.RootElement.ValueKind != JsonValueKind.Array ||
            result.RootElement.GetArrayLength() == 0)
        {
            throw new InvalidOperationException(
                "The notification was not marked as read. " +
                "Check the notification ID and staff permissions.");
        }
    }

    /// <summary>
    /// Adds the publishable key and authenticated user's access token.
    /// The publishable key is not an authorization bypass.
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

        request.Headers.Authorization =
            new AuthenticationHeaderValue("Bearer", accessToken);
    }

    /// <summary>
    /// Reads the configured Supabase project URL.
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
    /// Validates inputs before sending requests to Supabase.
    /// </summary>
    private static void ValidateRequest(
        long staffId,
        string accessToken)
    {
        if (staffId <= 0)
        {
            throw new ArgumentException(
                "A valid staff ID is required.",
                nameof(staffId));
        }

        if (string.IsNullOrWhiteSpace(accessToken))
        {
            throw new UnauthorizedAccessException(
                "A valid staff access token is required.");
        }
    }
}
