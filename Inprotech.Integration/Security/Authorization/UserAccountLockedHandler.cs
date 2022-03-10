using System;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Integration.Security.Authorization
{
    public class UserAccountLockedHandler : IHandleAsync<UserAccountLockedMessage>
    {
        readonly IIntegrationServerClient _jobsServer;

        public UserAccountLockedHandler(IIntegrationServerClient jobsServer)
        {
            _jobsServer = jobsServer;
        }
        public async Task HandleAsync(UserAccountLockedMessage message)
        {
            await _jobsServer.Post("api/jobs/UserAccountLocked/start", message);
        }
    }
}