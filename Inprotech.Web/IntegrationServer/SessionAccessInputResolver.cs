using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.IntegrationServer
{
    public interface ISessionAccessTokenInputResolver
    {
        bool TryResolve(out int userId, out long sessionId);
    }

    public class SessionAccessTokenInputResolver : ISessionAccessTokenInputResolver
    {
        readonly IAuthSettings _authSettings;
        readonly ICurrentOwinContext _currentOwinContext;

        public SessionAccessTokenInputResolver(ICurrentOwinContext currentOwinContext, IAuthSettings authSettings)
        {
            _currentOwinContext = currentOwinContext;
            _authSettings = authSettings;
        }

        public bool TryResolve(out int userId, out long sessionId)
        {
            userId = int.MinValue;
            sessionId = long.MinValue;

            var cookieData = _currentOwinContext.OwinContext.Request.ParseAuthCookie(_authSettings);
            if (cookieData != null)
            {
                sessionId = cookieData.LogId;
                userId = cookieData.UserId;
                return true;
            }

            return false;
        }
    }
}