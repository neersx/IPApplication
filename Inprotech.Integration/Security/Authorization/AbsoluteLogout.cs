using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Integration.Security.Authorization
{
    public class AbsoluteLogout
    {
        readonly IUserIdentityAccessManager _accessManager;

        public AbsoluteLogout(IUserIdentityAccessManager accessManager)
        {
            _accessManager = accessManager;
        }

        public Task Trigger()
        {
            return _accessManager.EndExpiredSessions();
        }
    }
}
