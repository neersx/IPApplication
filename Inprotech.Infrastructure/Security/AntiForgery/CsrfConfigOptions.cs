using Microsoft.Owin;

namespace Inprotech.Infrastructure.Security.AntiForgery
{
    public class CsrfConfigOptions
    {
        public const string CookieName = "XSRF-TOKEN";

        public const string HeaderName = "X-XSRF-TOKEN";

        public CsrfConfigOptions()
        {
            ShouldIssueCsrfToken = IsEnabled;
        }

        public string[] SafeMethods => new[] {"GET", "HEAD", "OPTIONS", "TRACE"};

        public string[] IgnoreUrls => new[] {"batcheventupdate", "inprodoc", "e2e"};

        public static string Path { get; set; }

        public static string Domain { get; set; }

        public static bool IsEnabled { get; set; }

        public bool ShouldIssueCsrfToken { get; set; }

        public CookieOptions GetCookieOptions()
        {
            return new CookieOptions
            {
                HttpOnly = false,
                Path = Path,
                Domain = Domain
            };
        }
    }
}