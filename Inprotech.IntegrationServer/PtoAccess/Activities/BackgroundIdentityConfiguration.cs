using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.IntegrationServer.PtoAccess.Activities
{
    public class BackgroundIdentityConfiguration
    {
        readonly ISecurityContext _securityContext;

        public BackgroundIdentityConfiguration(ISecurityContext securityContext)
        {
            _securityContext = securityContext;
        }

        public Task ValidateExists()
        {
            var user = _securityContext.User;

            return Task.FromResult(0);
        }
    }
}
