using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Reports.Job;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Integration.Jobs;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.TempStorage;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Reports
{
    public class StandardReportExecutionFacts
    {
        [Fact]
        public async Task ScheduleExportExecutionJob()
        {
            var jobServer = Substitute.For<IIntegrationServerClient>();
            var jobArgsStorage = Substitute.For<IJobArgsStorage>();
            var logger = Substitute.For<ILogger<ReportExecutionHandler>>();

            var storageId = Fixture.Long();
            jobArgsStorage.CreateAsync(Arg.Any<ReportGenerationRequiredMessage>()).Returns(storageId);
            var subject = new ReportExecutionHandler(logger, jobServer, jobArgsStorage);

            await subject.HandleAsync(new ReportGenerationRequiredMessage(new ReportRequest()));

            jobServer.Received(1)
                     .Post("api/jobs/StandardReportExecutionJob/start", Arg.Any<dynamic>());
        }

        public class JobStorageFacts : FactBase
        {
            [Fact]
            public async Task ShouldCreateTempStorageWithJobArgs()
            {
                var jobArgs = new ReportGenerationRequiredMessage(new ReportRequest
                {
                    ContentId = Fixture.Integer(),
                    UserIdentityKey = Fixture.Integer(),
                    UserCulture = "en-US"
                });

                var subject = new JobArgsStorage(Db);

                var actual = await subject.CreateAsync(jobArgs);

                var dbRecord = Db.Set<TempStorage>().Last();
                var data = JsonConvert.DeserializeObject<ReportGenerationRequiredMessage>(dbRecord.Value);

                Assert.Equal(dbRecord.Id, actual);
                Assert.NotNull(jobArgs);
                Assert.Equal(jobArgs.ReportRequestModel.ContentId, data.ReportRequestModel.ContentId);
                Assert.Equal(jobArgs.ReportRequestModel.UserIdentityKey, data.ReportRequestModel.UserIdentityKey);
                Assert.Equal(jobArgs.ReportRequestModel.UserCulture, data.ReportRequestModel.UserCulture);
            }
        }

        public class StandardReportExecutionJobFacts : FactBase
        {
            public class GetJobMethod : FactBase
            {
                [Fact]
                public void ReturnsStandardReportExecutionJobActivity()
                {
                    var storageId = Fixture.Long();
                    var original = new {StorageId = storageId};

                    var r = new StandardReportExecutionJob()
                        .GetJob(JObject.FromObject(original));

                    Assert.Equal("StandardReportExecutionJob.RenderReport", r.TypeAndMethod());

                    var arg = (long) r.Arguments[0];

                    Assert.Equal(storageId, arg);
                }
            }

            public class RenderReportMethod : FactBase
            {
                [Fact]
                public async Task ReturnsStandardReportExecutionJobActivity()
                {
                    var storageId = Fixture.Long();

                    var job = new StandardReportExecutionJob();
                    var r = await job.RenderReport(storageId);

                    Assert.NotNull(r);
                    var activity = (SingleActivity) r;
                    Assert.Equal("ReportEngine.Execute", activity.TypeAndMethod());
                    Assert.Equal(storageId, (long) activity.Arguments[0]);
                }
            }
        }
    }
}