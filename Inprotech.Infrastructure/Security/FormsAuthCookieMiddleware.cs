using Microsoft.Owin;
using Microsoft.Owin.Security.Cookies;
using Microsoft.Owin.Security.Infrastructure;

namespace Inprotech.Infrastructure.Security
{
    public class FormsAuthCookieMiddleware : AuthenticationMiddleware<CookieAuthenticationOptions>
    {
        readonly FormsAuthHandler _formsAuthHandler;

        public FormsAuthCookieMiddleware(OwinMiddleware next, CookieAuthenticationOptions options, FormsAuthHandler formsAuthHandler) : base(next, options)
        {
            _formsAuthHandler = formsAuthHandler;
        }

        protected override AuthenticationHandler<CookieAuthenticationOptions> CreateHandler()
        {
            return _formsAuthHandler;
        }
    }
}