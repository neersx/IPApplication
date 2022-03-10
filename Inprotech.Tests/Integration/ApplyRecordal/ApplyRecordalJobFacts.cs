using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.ApplyRecordal;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.ApplyRecordal
{
    public class ApplyRecordalHandlerFacts
    {
        [Fact]
        public async Task ScheduleApplyRecordalJob()
        {
            var jobServer = Substitute.For<IIntegrationServerClient>();

            var subject = new ApplyRecordalHandler(jobServer);

            await subject.HandleAsync(new ApplyRecordalArgs());

            jobServer.Received(1)
                     .Post("api/jobs/ApplyRecordalJob/start", Arg.Any<dynamic>());
        }
    }

    public class ApplyRecordalJobFacts
    {
        public class GetJobMethod : FactBase
        {
            [Fact]
            public void ReturnsApplyRecordalJobActivity()
            {
                var original = new ApplyRecordalArgs();

                var r = new ApplyRecordalJob()
                    .GetJob(JObject.FromObject(original));

                Assert.Equal("ApplyRecordalJob.Execute", r.TypeAndMethod());

                var arg = (ApplyRecordalArgs) r.Arguments[0];

                Assert.Equal(arg.GetType(), arg.GetType());
            }
        }

        public class ExecuteMethod : FactBase
        {
            [Fact]
            public async Task ReturnsApplyRecordalJobActivity()
            {
                var args = new ApplyRecordalArgs();
                var r = await new ApplyRecordalJob().Execute(args);

                Assert.NotNull(r);
                var activityItems = ((ActivityGroup) r).Items.ToList();
                Assert.Equal(activityItems.Count, 2);
                Assert.Equal(((SingleActivity) activityItems[0]).Name, "Run");
                Assert.Equal(((SingleActivity) activityItems[1]).Name, "AddBackgroundProcess");

                var arg = (ApplyRecordalArgs) ((SingleActivity) activityItems[0]).Arguments[0];
                Assert.Equal(arg.GetType(), arg.GetType());
            }
        }
    }
}