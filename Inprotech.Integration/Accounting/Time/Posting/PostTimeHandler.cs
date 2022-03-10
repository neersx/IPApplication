using System.Threading.Tasks;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Accounting.Time;

namespace Inprotech.Integration.Accounting.Time.Posting
{
    public class PostTimeHandler : IHandleAsync<PostTimeArgs>
    {
        readonly IIntegrationServerClient _jobsServer;

        public PostTimeHandler(IIntegrationServerClient jobsServer)
        {
            _jobsServer = jobsServer;
        }

        public async Task HandleAsync(PostTimeArgs args)
        {
            await _jobsServer.Post("api/jobs/PostTimeJob/start", args);
        }
    }
}