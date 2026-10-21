
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

namespace CUTClinic.Web.Services
{
    /// <summary>
    /// Authenticates users through Supabase Auth and checks
    /// whether the authenticated user is registered as clinic staff.
    /// </summary>
    public sealed class SupabaseAuthService
    {
        private readonly HttpClient _httpClient;
        private readonly string _supabaseUrl;
        private readonly string _publishableKey;

        public SupabaseAuthService(
            HttpClient httpClient,
            IConfiguration configuration)
        {
            _httpClient = httpClient;

            _supabaseUrl =
                configuration["Supabase:Url"]?.TrimEnd('/')
                ?? throw new InvalidOperationException(
                    "Supabase URL is missing.");

            _publishableKey =
                configuration["Supabase:PublishableKey"]
                ?? throw new InvalidOperationException(
                    "Supabase publishable key is missing.");
        }

        /// <summary>
        /// Signs in through Supabase Auth and verifies that the
        /// authenticated user has a matching staff table record.
        /// Never logs or stores the supplied password.
        /// </summary>
        public async Task<StaffLoginResult> AuthenticateStaffAsync(
            string email,
            string password)
        {
            if (string.IsNullOrWhiteSpace(email) ||
                string.IsNullOrWhiteSpace(password))
            {
                return StaffLoginResult.Failed(
                    "Enter your email address and password.");
            }

            try
            {
                // -----------------------------------------
                // CHECK 1: Authenticate with Supabase Auth.
                // -----------------------------------------

                var signInUrl =
                    $"{_supabaseUrl}/auth/v1/token?grant_type=password";

                using var signInRequest =
                    new HttpRequestMessage(
                        HttpMethod.Post,
                        signInUrl);

                signInRequest.Headers.Add(
                    "apikey",
                    _publishableKey);

                signInRequest.Content = JsonContent.Create(
                    new
                    {
                        email = email.Trim(),
                        password
                    });

                using var signInResponse =
                    await _httpClient.SendAsync(signInRequest);

                if (!signInResponse.IsSuccessStatusCode)
                {
                    // Do not reveal whether the email exists.
                    return StaffLoginResult.Failed(
                        "Login failed. Check your email and password.");
                }

                var authResponse =
                    await signInResponse.Content
                        .ReadFromJsonAsync<SupabaseSignInResponse>();

                var accessToken = authResponse?.AccessToken;
                var userId = authResponse?.User?.Id;

                if (string.IsNullOrWhiteSpace(accessToken) ||
                    !Guid.TryParse(userId, out var parsedUserId))
                {
                    return StaffLoginResult.Failed(
                        "Supabase returned an invalid login response.");
                }

                // -----------------------------------------
                // CHECK 2: Verify the matching staff record.
                // -----------------------------------------

                // Use the authenticated user's token so the
                // existing Supabase RLS policies are respected.
                var staffUrl =
                    $"{_supabaseUrl}/rest/v1/staff" +
                    $"?auth_user_id=eq.{parsedUserId:D}" +
                    "&select=staff_id,auth_user_id,full_name,email" +
                    "&limit=1";

                using var staffRequest =
                    new HttpRequestMessage(
                        HttpMethod.Get,
                        staffUrl);

                staffRequest.Headers.Add(
                    "apikey",
                    _publishableKey);

                staffRequest.Headers.Authorization =
                    new AuthenticationHeaderValue(
                        "Bearer",
                        accessToken);

                staffRequest.Headers.Accept.Add(
                    new MediaTypeWithQualityHeaderValue(
                        "application/json"));

                using var staffResponse =
                    await _httpClient.SendAsync(staffRequest);

                if (!staffResponse.IsSuccessStatusCode)
                {
                    // This may indicate an RLS policy, permission,
                    // API exposure, or configuration problem.
                    // Do not bypass RLS or expose database details.
                    return StaffLoginResult.Failed(
                        "We could not verify staff authorization. " +
                        "Please contact the system administrator.");
                }

                var staffRecords =
                    await staffResponse.Content
                        .ReadFromJsonAsync<List<StaffRecord>>();

                if (staffRecords is null ||
                    staffRecords.Count != 1 ||
                    staffRecords[0] is null)
                {
                    return StaffLoginResult.Failed(
                        "This account is not registered for staff access.");
                }

                var staff = staffRecords[0];

                // Confirm the returned record matches the Auth user.
                if (!Guid.TryParse(
                        staff.AuthUserId,
                        out var staffAuthUserId) ||
                    staffAuthUserId != parsedUserId)
                {
                    return StaffLoginResult.Failed(
                        "Staff authorization could not be verified.");
                }

                if (string.IsNullOrWhiteSpace(staff.Email) ||
                    string.IsNullOrWhiteSpace(staff.FullName))
                {
                    return StaffLoginResult.Failed(
                        "The staff profile is incomplete. " +
                        "Please contact the system administrator.");
                }

                // Return the verified staff details and the
                // access token for the next authentication step.
                // The controller must protect the session and must
                // never return the access token to the browser as JSON.
                return StaffLoginResult.Succeeded(
                    staff,
                    accessToken,
                    authResponse?.ExpiresIn ?? 0);
            }
            catch (HttpRequestException)
            {
                return StaffLoginResult.Failed(
                    "Could not connect to Supabase. Please try again.");
            }
            catch (TaskCanceledException)
            {
                return StaffLoginResult.Failed(
                    "The login request timed out. Please try again.");
            }
        }

        // ---------------------------------------------
        // Supabase Auth response models.
        // ---------------------------------------------

        private sealed class SupabaseSignInResponse
        {
            [JsonPropertyName("access_token")]
            public string? AccessToken { get; set; }

            [JsonPropertyName("expires_in")]
            public int ExpiresIn { get; set; }

            [JsonPropertyName("user")]
            public SupabaseUser? User { get; set; }
        }

        private sealed class SupabaseUser
        {
            [JsonPropertyName("id")]
            public string? Id { get; set; }
        }
    }

    /// <summary>
    /// A verified row from the existing staff table.
    /// </summary>
    public sealed class StaffRecord
    {
        [JsonPropertyName("staff_id")]
        public long StaffId { get; set; }

        [JsonPropertyName("auth_user_id")]
        public string? AuthUserId { get; set; }

        [JsonPropertyName("full_name")]
        public string? FullName { get; set; }

        [JsonPropertyName("email")]
        public string? Email { get; set; }
    }

    /// <summary>
    /// Result returned by the staff login service.
    /// </summary>
    public sealed class StaffLoginResult
    {
        public bool Success { get; private set; }

        public string Message { get; private set; } = string.Empty;

        public StaffRecord? Staff { get; private set; }

        public string? AccessToken { get; private set; }

        public int ExpiresIn { get; private set; }

        private StaffLoginResult()
        {
        }

        public static StaffLoginResult Failed(string message)
        {
            return new StaffLoginResult
            {
                Success = false,
                Message = message
            };
        }

        public static StaffLoginResult Succeeded(
            StaffRecord staff,
            string accessToken,
            int expiresIn)
        {
            return new StaffLoginResult
            {
                Success = true,
                Message = "Staff authorization verified.",
                Staff = staff,
                AccessToken = accessToken,
                ExpiresIn = expiresIn
            };
        }
    }
}

