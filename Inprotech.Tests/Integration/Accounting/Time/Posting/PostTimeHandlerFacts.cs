using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Accounting.Time.Posting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Accounting.Time.Posting
{
    public class PostTimeHandlerFacts
    {
        [Fact]
        public async Task SchedulePostTimeJob()
        {
            var jobServer = Substitute.For<IIntegrationServerClient>();

            var subject = new PostTimeHandler(jobServer);

            await subject.HandleAsync(new PostTimeArgs());
                
            jobServer.Received(1)
                     .Post("api/jobs/PostTimeJob/start", Arg.Any<dynamic>());
        }
    }
}
