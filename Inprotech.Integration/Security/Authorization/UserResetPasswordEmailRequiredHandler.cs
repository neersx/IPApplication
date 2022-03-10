using System.Threading.Tasks;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Integration.Security.Authorization
{
    public class UserResetPasswordEmailRequiredHandler : IHandleAsync<UserResetPasswordMessage>
    {
        readonly IIntegrationServerClient _jobsServer;

        public UserResetPasswordEmailRequiredHandler(IIntegrationServerClient jobsServer)
        {
            _jobsServer = jobsServer;
        }

        public async Task HandleAsync(UserResetPasswordMessage message)
        {
            await _jobsServer.Post("api/jobs/UserResetPasswordEmailRequired/start", message);
        }
    }
}
