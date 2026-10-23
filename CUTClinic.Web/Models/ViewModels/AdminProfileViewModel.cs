
using System;

namespace CUTClinic.Web.ViewModels
{
    /// <summary>
    /// Contains profile information for the currently signed-in
    /// account. Values are populated from authenticated claims;
    /// no new database table is required.
    /// </summary>
    public sealed class AdminProfileViewModel
    {
        /// <summary>
        /// The display name stored in the authentication claims.
        /// </summary>
        public string FullName { get; set; } = string.Empty;

        /// <summary>
        /// The email address stored in the authentication claims.
        /// </summary>
        public string Email { get; set; } = string.Empty;

        /// <summary>
        /// The role assigned by the authentication system.
        /// This must not be used to grant permissions.
        /// </summary>
        public string Role { get; set; } = string.Empty;

        /// <summary>
        /// Indicates whether the current account is authenticated.
        /// </summary>
        public bool IsAuthenticated { get; set; }
    }
}
