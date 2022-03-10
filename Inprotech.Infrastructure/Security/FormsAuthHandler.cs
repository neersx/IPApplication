using System;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Web.Security;
using Inprotech.Infrastructure.Security.AntiForgery;
using Microsoft.Owin;
using Microsoft.Owin.Security;
using Microsoft.Owin.Security.Cookies;
using Microsoft.Owin.Security.Infrastructure;

namespace Inprotech.Infrastructure.Security
{
    public class FormsAuthHandler : AuthenticationHandler<CookieAuthenticationOptions>
    {
        readonly ITokenExtender _tokenExtender;

        public FormsAuthHandler(ITokenExtender tokenExtender)
        {
            _tokenExtender = tokenExtender;
        }

        protected override async Task<AuthenticationTicket> AuthenticateCoreAsync()
        {
            var encryptedTicket = Request.Cookies[Options.CookieName];

            if (string.IsNullOrWhiteSpace(encryptedTicket))
            {
                return null;
            }

            var ticket = FormsAuthentication.Decrypt(encryptedTicket);

            if (ticket == null || ticket.Expired)
            {
                return null;
            }

            var cookieData = ticket.ParseAuthCookie();

            if (cookieData != null)
            {
                if (!Request.Context.Environment.ContainsKey(nameof(AuthCookieData.AuthMode)))
                {
                    Request.Context.Environment.Add(nameof(AuthCookieData.AuthMode), cookieData.AuthMode);
                }

                if (!Request.Context.Environment.ContainsKey(nameof(AuthCookieData.LogId)))
                {
                    Request.Context.Environment.Add(nameof(AuthCookieData.LogId), cookieData.LogId);
                }

                if (!string.IsNullOrWhiteSpace(cookieData.Auth2FaMode) && !Request.Context.Environment.ContainsKey(nameof(AuthCookieData.Auth2FaMode)))
                {
                    Request.Context.Environment.Add(nameof(AuthCookieData.Auth2FaMode), cookieData.Auth2FaMode);
                    Request.Context.Environment.Add("Auth2FaModeGranted", ticket.IssueDate);
                }
            }

            var oldExpiryTime = ticket.Expiration;

            ticket = FormsAuthentication.RenewTicketIfOld(ticket);

            if (ticket.Expiration != oldExpiryTime)
            {
                var (shouldExtend, tokenValid) = await _tokenExtender.ShouldExtend(cookieData);

                if (shouldExtend)
                {
                    encryptedTicket = FormsAuthentication.Encrypt(ticket);
                    Response.Cookies.Append(Options.CookieName, encryptedTicket, ticket.GetCookieOptions(IsSecure(Request), Options.CookieDomain));

                    AddCsrfCookie(encryptedTicket);
                }

                if (!tokenValid)
                {
                    ExpireCookie(ticket);
                    return null;
                }
            }

            var id = new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.Name, ticket.Name)
            }, Options.AuthenticationType);

            return new AuthenticationTicket(id, new AuthenticationProperties());
        }

        void AddCsrfCookie(string encryptedTicket)
        {
            var csrfOptions = Context.GetCsrfConfigOptions();
            if (csrfOptions.ShouldIssueCsrfToken)
            {
                Response.Cookies.Append(CsrfConfigOptions.CookieName,
                                        AntiForgeryToken.Generate(encryptedTicket),
                                        csrfOptions.GetCookieOptions());
            }
        }

        void ExpireCookie(FormsAuthenticationTicket ticket)
        {
            var expiredCookie = new FormsAuthenticationTicket(
                                                              ticket.Version,
                                                              ticket.Name,
                                                              ticket.IssueDate,
                                                              new DateTime(1999, 1, 1),
                                                              ticket.IsPersistent,
                                                              ticket.UserData,
                                                              ticket.CookiePath);

            Response.Cookies.Append(Options.CookieName, FormsAuthentication.Encrypt(expiredCookie), ticket.GetCookieOptions(IsSecure(Request), Options.CookieDomain));
        }

        static bool IsSecure(IOwinRequest request)
        {
            return request.Scheme == Uri.UriSchemeHttps;
        }
    }
}