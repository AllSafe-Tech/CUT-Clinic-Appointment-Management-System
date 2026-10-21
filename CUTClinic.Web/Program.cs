
using Microsoft.AspNetCore.Authentication.Cookies;
using System.Net.Http.Headers;
using CUTClinic.Web.Services;

var builder = WebApplication.CreateBuilder(args);

// =====================================================
// 1. REGISTER APPLICATION SERVICES
// =====================================================

// Register MVC controllers and views.
builder.Services.AddControllersWithViews();


// Register HttpClient for Supabase HTTP requests.
builder.Services.AddHttpClient();


builder.Services.AddScoped<SupabaseAppointmentService>();
// Registers the service used by the staff in-app notifications screen.
builder.Services.AddScoped<SupabaseStaffNotificationService>();
builder.Services.AddHttpClient<SupabaseAuthService>();
// Registers the Gmail email service for dependency injection.
builder.Services.AddScoped<GmailEmailService>();
// Configure protected authentication cookies for clinic staff.
// A cookie is issued only after the login service verifies
// the user's Supabase Auth account and staff database record.
builder.Services
    .AddAuthentication(
        CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.Cookie.Name = "CUTClinic.StaffSession";
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy =
            CookieSecurePolicy.Always;
        options.Cookie.SameSite = SameSiteMode.Lax;

        options.LoginPath = "/Account/Login";
        options.AccessDeniedPath = "/Account/AccessDenied";

        options.ExpireTimeSpan = TimeSpan.FromMinutes(30);
        options.SlidingExpiration = true;
    });

// =====================================================
// 2. LOAD AND VALIDATE SUPABASE CONFIGURATION
// =====================================================

// Keep using the existing configuration and User Secrets.
var supabaseUrl = builder.Configuration["Supabase:Url"];
var supabasePublishableKey =
    builder.Configuration["Supabase:PublishableKey"];

if (string.IsNullOrWhiteSpace(supabaseUrl) ||
    string.IsNullOrWhiteSpace(supabasePublishableKey))
{
    throw new InvalidOperationException(
        "Supabase configuration is missing. " +
        "Check your ASP.NET Core User Secrets.");
}

// Validate the Supabase project URL.
if (!Uri.TryCreate(
        supabaseUrl,
        UriKind.Absolute,
        out var parsedSupabaseUrl) ||
    parsedSupabaseUrl.Scheme != Uri.UriSchemeHttps ||
    !string.IsNullOrEmpty(parsedSupabaseUrl.UserInfo) ||
    !string.IsNullOrEmpty(parsedSupabaseUrl.Query) ||
    !string.IsNullOrEmpty(parsedSupabaseUrl.Fragment))
{
    throw new InvalidOperationException(
        "The Supabase URL must be a valid HTTPS project URL.");
}

// =====================================================
// 3. BUILD THE APPLICATION
// =====================================================

var app = builder.Build();

// =====================================================
// 4. CONFIGURE THE HTTP REQUEST PIPELINE
// =====================================================

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseRouting();

// Authenticate requests before applying authorization rules.
app.UseAuthentication();

app.UseAuthorization();

// Keep the .NET 10 static asset convention.
app.MapStaticAssets();

// Keep the existing MVC route.
app.MapControllerRoute(
        name: "default",
        pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();

// =====================================================
// 5. DEVELOPMENT-ONLY SUPABASE HEALTH CHECK
// =====================================================

// This checks the Supabase Auth health endpoint.
// It does not authenticate a staff member or test database RLS.
if (app.Environment.IsDevelopment())
{
    app.MapGet(
        "/supabase-status",
        async (IHttpClientFactory httpClientFactory) =>
        {
            try
            {
                var client = httpClientFactory.CreateClient();
                client.Timeout = TimeSpan.FromSeconds(15);

                var healthUrl =
                    $"{supabaseUrl.TrimEnd('/')}/auth/v1/health";

                using var request = new HttpRequestMessage(
                    HttpMethod.Get,
                    healthUrl);

                request.Headers.Add(
                    "apikey",
                    supabasePublishableKey);

                using var response =
                    await client.SendAsync(request);

                if (response.IsSuccessStatusCode)
                {
                    return Results.Ok(new
                    {
                        status = "Connected",
                        message =
                            "Supabase Auth health endpoint responded successfully."
                    });
                }

                return Results.Problem(
                    "The Supabase health check failed. " +
                    $"HTTP status: {(int)response.StatusCode}.",
                    statusCode: (int)response.StatusCode);
            }
            catch (TaskCanceledException)
            {
                return Results.Problem(
                    "The Supabase health check timed out.",
                    statusCode: StatusCodes.Status504GatewayTimeout);
            }
            catch (HttpRequestException)
            {
                return Results.Problem(
                    "Could not reach the Supabase health endpoint.",
                    statusCode: StatusCodes.Status502BadGateway);
            }
        });

    // =================================================
    // 6. READ-ONLY APPOINTMENTS TABLE TEST
    // =================================================

    app.MapGet(
        "/supabase-database-test",
        async (IHttpClientFactory httpClientFactory) =>
        {
            try
            {
                var client = httpClientFactory.CreateClient();
                client.Timeout = TimeSpan.FromSeconds(15);

                // Request only the primary-key column.
                // Limit the response to one row.
                // This request does not modify records.
                var tableUrl =
                    $"{supabaseUrl.TrimEnd('/')}" +
                    "/rest/v1/appointments" +
                    "?select=appointment_id&limit=1";

                using var request = new HttpRequestMessage(
                    HttpMethod.Get,
                    tableUrl);

                // Identify the Supabase project using the
                // existing publishable key.
                request.Headers.Add(
                    "apikey",
                    supabasePublishableKey);

                request.Headers.Accept.Add(
                    new MediaTypeWithQualityHeaderValue(
                        "application/json"));

                using var response =
                    await client.SendAsync(request);

                if (response.IsSuccessStatusCode)
                {
                    return Results.Ok(new
                    {
                        status = "Database query successful",
                        table = "appointments",
                        column = "appointment_id",
                        operation = "Read-only SELECT",
                        message =
                            "Supabase accepted the query. " +
                            "The appointments table endpoint is accessible " +
                            "under the current permissions."
                    });
                }

                // Do not return response bodies, credentials,
                // or potentially sensitive database details.
                var statusCode = (int)response.StatusCode;

                var message = statusCode switch
                {
                    401 =>
                        "Authentication or API-key validation failed.",

                    403 =>
                        "The database request was forbidden. " +
                        "Check the existing grants and RLS policies.",

                    404 =>
                        "The REST endpoint or requested table was not found. " +
                        "Verify the table name and API exposure.",

                    _ =>
                        "The database query failed. " +
                        $"HTTP status: {statusCode}."
                };

                return Results.Problem(
                    message,
                    statusCode: statusCode);
            }
            catch (TaskCanceledException)
            {
                return Results.Problem(
                    "The Supabase database request timed out.",
                    statusCode: StatusCodes.Status504GatewayTimeout);
            }
            catch (HttpRequestException)
            {
                return Results.Problem(
                    "Could not reach the Supabase database API.",
                    statusCode: StatusCodes.Status502BadGateway);
            }
        });
}

// =====================================================
// 7. START THE APPLICATION
// =====================================================

app.Run();
