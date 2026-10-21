
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using CUTClinic.Web.Models;
using CUTClinic.Web.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CUTClinic.Web.Controllers
{
    public sealed class AccountController : Controller
    {
        private readonly SupabaseAuthService _authService;

        public AccountController(SupabaseAuthService authService)
        {
            _authService = authService;
        }

        // GET: /Account/Login
        [AllowAnonymous]
        [HttpGet]
        public IActionResult Login()
        {
            if (User.Identity?.IsAuthenticated == true)
            {
                return RedirectToAction("Index", "Home");
            }

            return View(new StaffLoginViewModel());
        }

        // POST: /Account/Login
        [AllowAnonymous]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(
            StaffLoginViewModel model)
        {
            if (!ModelState.IsValid)
            {
                model.Password = string.Empty;
                return View(model);
            }

            var result = await _authService.AuthenticateStaffAsync(
                model.Email,
                model.Password);

            // Never create a session unless both Supabase
            // authentication and staff verification succeeded.
            if (!result.Success ||
                result.Staff is null ||
                string.IsNullOrWhiteSpace(result.AccessToken))
            {
                ModelState.AddModelError(
                    string.Empty,
                    result.Message);

                model.Password = string.Empty;
                return View(model);
            }

            // Leave a safety margin before the Supabase token expires.
            var tokenLifetimeSeconds = result.ExpiresIn - 60;

            if (tokenLifetimeSeconds <= 0)
            {
                ModelState.AddModelError(
                    string.Empty,
                    "The authentication session could not be established. " +
                    "Please sign in again.");

                model.Password = string.Empty;
                return View(model);
            }

            var staff = result.Staff;

            // The token claim is stored inside the ASP.NET Core
            // protected authentication ticket. Do not expose it
            // through a view, API response, or browser JavaScript.
            var claims = new List<Claim>
            {
                new Claim(
                    ClaimTypes.NameIdentifier,
                    staff.StaffId.ToString()),

                new Claim(
                    ClaimTypes.Name,
                    staff.FullName!),

                new Claim(
                    ClaimTypes.Email,
                    staff.Email!),

                new Claim(
                    ClaimTypes.Role,
                    "Staff"),

                new Claim(
                    "supabase_access_token",
                    result.AccessToken)
            };

            var identity = new ClaimsIdentity(
                claims,
                CookieAuthenticationDefaults.AuthenticationScheme);

            var principal = new ClaimsPrincipal(identity);

            var expiresAt = DateTimeOffset.UtcNow.AddSeconds(
                tokenLifetimeSeconds);

            var properties = new AuthenticationProperties
            {
                IsPersistent = true,
                ExpiresUtc = expiresAt,
                AllowRefresh = false
            };

            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                principal,
                properties);

            // Clear the password from the model before leaving
            // the login action.
            model.Password = string.Empty;

            return RedirectToAction("Index", "Home");
        }

        // POST: /Account/Logout
        [Authorize(Roles = "Staff")]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(
                CookieAuthenticationDefaults.AuthenticationScheme);

            return RedirectToAction(nameof(Login));
        }

        // GET: /Account/AccessDenied
        [AllowAnonymous]
        [HttpGet]
        public IActionResult AccessDenied()
        {
            return View();
        }
        // TEMPORARY: Verify the current staff authentication session.
        [Authorize(Roles = "Staff")]
        [HttpGet]
        public IActionResult SessionTest()
        {
            return Json(new
            {
                IsAuthenticated = User.Identity?.IsAuthenticated,
                Name = User.Identity?.Name,
                IsStaff = User.IsInRole("Staff")
            });
        }
    }

}
