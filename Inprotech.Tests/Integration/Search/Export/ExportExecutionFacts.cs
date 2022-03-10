using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Storage;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Search.Export;
using Inprotech.Integration.Search.Export.Jobs;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Integration.Jobs;
using InprotechKaizen.Model.TempStorage;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Search.Export
{
    public class ExportExecutionHandlerFacts
    {
        [Fact]
        public async Task ScheduleExportExecutionJob()
        {
            var jobServer = Substitute.For<IIntegrationServerClient>();
            var exportJobArgsStorage = Substitute.For<IJobArgsStorage>();

            var storageId = Fixture.Long();
            exportJobArgsStorage.CreateAsync(Arg.Any<ExportExecutionJobArgs>()).Returns(storageId);

            var subject = new ExportExecutionHandler(jobServer, exportJobArgsStorage);

            await subject.HandleAsync(new ExportExecutionJobArgs());

            jobServer.Received(1)
                     .Post("api/jobs/ExportExecutionJob/start", Arg.Any<dynamic>());
        }
    }

    public class ExportExecutionStorageFacts : FactBase
    {
        [Fact]
        public async Task ShouldCreateTempStorageWithJobArgs()
        {
            var jobArgs = new ExportExecutionJobArgs
            {
                ExportRequest = new ExportRequest {ExportFormat = ReportExportFormat.Excel},
                Settings = new SearchResultsSettings
                {
                    ApplicationName = Fixture.String(), MaxColumnsForExport = Fixture.Integer(), ReportFileName = Fixture.String()
                }
            };

            var subject = new JobArgsStorage(Db);

            var actual = await subject.CreateAsync(jobArgs);

            var dbRecord = Db.Set<TempStorage>().Last();
            var data = JsonConvert.DeserializeObject<ExportExecutionJobArgs>(dbRecord.Value);

            Assert.Equal(dbRecord.Id, actual);
            Assert.Equal(jobArgs.ExportRequest.ExportFormat, data.ExportRequest.ExportFormat);
            Assert.Equal(jobArgs.Settings.ReportFileName, data.Settings.ReportFileName);
            Assert.Equal(jobArgs.Settings.MaxColumnsForExport, data.Settings.MaxColumnsForExport);
            Assert.Equal(jobArgs.Settings.ApplicationName, data.Settings.ApplicationName);
        }
    }

    public class ExportExecutionJobFacts
    {
        public class GetJobMethod : FactBase
        {
            [Fact]
            public void ReturnsExportExecutionJobActivity()
            {
                var storageId = Fixture.Integer();
                var original = new {StorageId = storageId};

                var r = new ExportExecutionJob()
                    .GetJob(JObject.FromObject(original));

                Assert.Equal("ExportExecutionJob.ExecuteExport", r.TypeAndMethod());

                var arg = (int) r.Arguments[0];

                Assert.Equal(storageId, arg);
            }
        }

        public class ExecuteExportMethod : FactBase
        {
            [Fact]
            public async Task ReturnsExportExecutionJobActivity()
            {
                var storageId = Fixture.Integer();

                var r = await new ExportExecutionJob()
                    .ExecuteExport(storageId);

                Assert.NotNull(r);
                var activityItems = ((ActivityGroup) r).Items.ToList();
                Assert.Equal(activityItems.Count, 2);
                Assert.Equal(((SingleActivity) activityItems[0]).Name, "Execute");
                Assert.Equal(((SingleActivity) activityItems[1]).Name, "CleanUpTempStorage");

                var arg = (int) ((SingleActivity) activityItems[0]).Arguments[0];
                Assert.Equal(storageId, arg);
            }
        }
    }
}