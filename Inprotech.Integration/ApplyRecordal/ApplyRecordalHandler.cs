using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Web;
using System.Threading.Tasks;

namespace Inprotech.Integration.ApplyRecordal
{
    public class ApplyRecordalHandler : IHandleAsync<ApplyRecordalArgs>
    {
        readonly IIntegrationServerClient _jobsServer;

        public ApplyRecordalHandler(IIntegrationServerClient jobsServer)
        {
            _jobsServer = jobsServer;
        }

        public async Task HandleAsync(ApplyRecordalArgs args)
        {
            await _jobsServer.Post("api/jobs/ApplyRecordalJob/start", args);
        }
    }
}
