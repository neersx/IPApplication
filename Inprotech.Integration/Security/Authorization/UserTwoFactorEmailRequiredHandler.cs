using System.Threading.Tasks;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Integration.Security.Authorization
{
    public class UserTwoFactorEmailRequiredHandler : IHandleAsync<UserAccount2FaMessage>
    {
        readonly IIntegrationServerClient _jobsServer;

        public UserTwoFactorEmailRequiredHandler(IIntegrationServerClient jobsServer)
        {
            _jobsServer = jobsServer;
        }

        public async Task HandleAsync(UserAccount2FaMessage message)
        {
            await _jobsServer.Post("api/jobs/UserTwoFactorEmailRequired/start", message);
        }
    }
}