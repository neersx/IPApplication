using System;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.Security;
using Inprotech.Infrastructure.Security.AntiForgery;
using Microsoft.Owin;
using Newtonsoft.Json;

namespace Inprotech.Infrastructure.Security
{
    public static class AntiForgeryExtensions
    {
        public static CsrfConfigOptions GetCsrfConfigOptions(this IOwinContext context)
        {
            return new CsrfConfigOptions();
        }

        public static CsrfConfigOptions GetCsrfConfigOptions(this HttpRequestMessage request)
        {
            return new CsrfConfigOptions();
        }

        public static CsrfConfigOptions GetCsrfConfigOptions(this HttpResponseMessage response)
        {
            return response.RequestMessage.GetCsrfConfigOptions();
        }
    }

    public static class AuthCookieExtensions
    {
        public static IOwinResponse WithAuthCookie(this IOwinResponse response, IAuthSettings settings, AuthUser user)
        {
            var ticket = settings.CreateAuthTicket(user);

            var encryptedTicket = FormsAuthentication.Encrypt(ticket);

            response.Cookies.Append(settings.SessionCookieName,
                                    encryptedTicket,
                                    new CookieOptions
                                    {
                                        Path = settings.SessionCookiePath,
                                        Domain = settings.SessionCookieDomain,
                                        HttpOnly = true,
                                        Secure = IsSecure(response.Context.Request)
                                    });

            var csrfOptions = response.Context.GetCsrfConfigOptions();
            if (csrfOptions.ShouldIssueCsrfToken)
            {
                response.Cookies.Append(CsrfConfigOptions.CookieName,
                                        AntiForgeryToken.Generate(encryptedTicket),
                                        csrfOptions.GetCookieOptions());
            }

            return response;
        }

        public static HttpResponseMessage WithAuthCookie(this HttpResponseMessage response, IAuthSettings settings, AuthUser user)
        {
            var ticket = settings.CreateAuthTicket(user);

            var encryptedTicket = FormsAuthentication.Encrypt(ticket);

            var cookieHeaderCollection = new[]
            {
                new CookieHeaderValue(settings.SessionCookieName, encryptedTicket)
                {
                    Path = settings.SessionCookiePath,
                    Domain = settings.SessionCookieDomain,
                    HttpOnly = true,
                    Secure = IsSecure(response.RequestMessage)
                }
            }.ToList();

            var csrfOptions = response.GetCsrfConfigOptions();
            if (csrfOptions.ShouldIssueCsrfToken)
            {
                cookieHeaderCollection.Add(new CookieHeaderValue(CsrfConfigOptions.CookieName,
                                                                 AntiForgeryToken.Generate(encryptedTicket))
                {
                    Path = settings.SessionCookiePath,
                    Domain = settings.SessionCookieDomain,
                    Secure = IsSecure(response.RequestMessage)
                });
            }

            response.Headers.AddCookies(cookieHeaderCollection);

            return response;
        }

        public static HttpResponseMessage WithExpiredCookie(this HttpResponseMessage response, string sessionCookieName, string sessionCookiePath, string sessionCookieDomain)
        {
            var cookie = new CookieHeaderValue(sessionCookieName, string.Empty)
            {
                Path = sessionCookiePath,
                Domain = sessionCookieDomain,
                Expires = new DateTimeOffset(new DateTime(1999, 1, 1)),
                HttpOnly = true,
                Secure = IsSecure(response.RequestMessage)
            };

            var csrfOptions = new CsrfConfigOptions();
            var antiForgeryCookie = new CookieHeaderValue(CsrfConfigOptions.CookieName, string.Empty)
            {
                Path = csrfOptions.GetCookieOptions().Path,
                Domain = csrfOptions.GetCookieOptions().Domain,
                Expires = new DateTimeOffset(new DateTime(1999, 1, 1)),
                HttpOnly = csrfOptions.GetCookieOptions().HttpOnly,
                Secure = IsSecure(response.RequestMessage)
            };

            response.Headers.AddCookies(new[] {cookie, antiForgeryCookie});
            return response;
        }

        public static string ToJson(this AuthCookieData data)
        {
            return JsonConvert.SerializeObject(data);
        }

        static bool IsSecure(HttpRequestMessage message)
        {
            return message.RequestUri.Scheme == Uri.UriSchemeHttps;
        }

        static bool IsSecure(IOwinRequest request)
        {
            return request.Scheme == Uri.UriSchemeHttps;
        }

        public static CookieOptions GetCookieOptions(this FormsAuthenticationTicket ticket, bool secureFlag = false, string domain = null)
        {
            return new CookieOptions
            {
                Path = ticket.CookiePath,
                Domain = domain,
                HttpOnly = true,
                Secure = secureFlag
            };
        }
    }

    public static class AuthCookieDataExtensions
    {
        public static AuthCookieData ParseAuthCookie(this HttpRequestMessage request, IAuthSettings settings)
        {
            var cookies = request.Headers.GetCookies(settings.SessionCookieName).FirstOrDefault();

            var encryptedTicket = cookies?[settings.SessionCookieName].Value ?? string.Empty;

            return GetCookieData(encryptedTicket);
        }

        public static AuthCookieData ParseAuthCookie(this IOwinRequest request, IAuthSettings settings)
        {
            var encryptedTicket = request.Cookies[settings.SessionCookieName];
            return GetCookieData(encryptedTicket);
        }

        public static AuthCookieData ParseAuthCookie(this FormsAuthenticationTicket ticket)
        {
            return JsonConvert.DeserializeObject<AuthCookieData>(ticket.UserData);
        }

        public static (AuthCookieData data, DateTime expiration) ParseAuthCookieDataWithExpiry(this HttpRequestMessage request, IAuthSettings settings)
        {
            var cookies = request.Headers.GetCookies(settings.SessionCookieName).FirstOrDefault();

            var encryptedTicket = cookies?[settings.SessionCookieName].Value ?? string.Empty;

            var ticket = DecryptAuthTicket(encryptedTicket);
            if (ticket == null)
            {
                return (null, DateTime.MinValue);
            }

            return (ticket.ParseAuthCookie(), ticket.Expiration);
        }

        public static (AuthCookieData data, DateTime expiration) ParseAuthCookieDataWithExpiry(this IOwinRequest request, IAuthSettings settings)
        {
            var ticket = DecryptAuthTicket(request.Cookies[settings.SessionCookieName]);
            if (ticket == null)
            {
                return (null, DateTime.MinValue);
            }

            return (ticket.ParseAuthCookie(), ticket.Expiration);
        }

        static FormsAuthenticationTicket DecryptAuthTicket(string encryptedTicket)
        {
            FormsAuthenticationTicket ticket;
            if (string.IsNullOrWhiteSpace(encryptedTicket) || (ticket = FormsAuthentication.Decrypt(encryptedTicket)) == null)
            {
                return null;
            }

            return ticket;
        }

        static AuthCookieData GetCookieData(string encryptedTicket)
        {
            var ticket = DecryptAuthTicket(encryptedTicket);
            return ticket == null ? null : JsonConvert.DeserializeObject<AuthCookieData>(ticket.UserData);
        }
    }

    public class AuthUser
    {
        public AuthUser(string userName, int id, string authMode, long logId, string auth2FaMode = null)
        {
            Username = userName;
            UserId = id;
            AuthMode = authMode;
            LogId = logId;
            Auth2FaMode = auth2FaMode;
        }

        public int UserId { get; }

        public string Username { get; }

        public string AuthMode { get; }

        public long LogId { get; }

        public string Auth2FaMode { get; }
    }

    public class AuthCookieData
    {
        public AuthCookieData()
        {
        }

        public AuthCookieData(AuthUser user, bool preventManualLogout) : this()
        {
            UserId = user.UserId;
            AuthMode = user.AuthMode;
            PreventManualLogout = preventManualLogout;
            LogId = user.LogId;
            Auth2FaMode = user.Auth2FaMode;
        }

        public int UserId { get; set; }

        public string AuthMode { get; set; }

        public bool PreventManualLogout { get; set; }

        public long LogId { get; set; }

        public string Auth2FaMode { get; set; }
    }
}