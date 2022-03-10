using System;
using System.Security.Cryptography;
using System.Text;
using System.Web;

namespace Inprotech.Infrastructure.Security.AntiForgery
{
    public static class AntiForgeryToken
    {
        const string Salt = "Cpagl0bal";

        public static string Generate(string authToken)
        {
            if (string.IsNullOrEmpty(authToken)) throw new ArgumentNullException(nameof(authToken));

            return GenerateCookieFriendlyHash(authToken);
        }

        public static bool Validate(string csrfToken, string csrfCookieToken)
        {
            return string.Equals(csrfToken, csrfCookieToken);
        }

        static string GenerateCookieFriendlyHash(string authToken)
        {
            using (var sha = SHA256.Create())
            {
                var computedHash = sha.ComputeHash(Encoding.Unicode.GetBytes(authToken + Salt));
                var cookieFriendlyHash = HttpServerUtility.UrlTokenEncode(computedHash);
                return cookieFriendlyHash;
            }
        }
    }
}