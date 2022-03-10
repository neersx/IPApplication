using System.Threading.Tasks;
using Inprotech.Contracts.Messages;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Integration.Email
{
    public class EventNotesMailMessageHandler : IHandleAsync<EventNotesMailMessage>
    {
        readonly IIntegrationServerClient _jobsServer;

        public EventNotesMailMessageHandler(IIntegrationServerClient jobsServer)
        {
            _jobsServer = jobsServer;
        }

        public async Task HandleAsync(EventNotesMailMessage message)
        {
            await _jobsServer.Post("api/jobs/EventNotesMailMessageExecution/start", message);
        }
    }
}
