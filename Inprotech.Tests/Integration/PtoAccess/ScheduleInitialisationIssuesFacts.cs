using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class ScheduleInitialisationIssuesFacts
    {
        public class PrepareMethod : FactBase
        {
            [Fact]
            public async Task DoesNotSaveWhenErrorsWereAssociatedWithDeletedSchedules()
            {
                var guid = Guid.NewGuid();
                var error = new ErrorBuilder
                {
                    ActivityType = GetType().AssemblyQualifiedName,
                    Message = "Oh bummer!"
                }.Build();

                var s = new Schedule().In(Db);
                var se = new ScheduleExecution(guid, s, Fixture.Today(), Fixture.String()).In(Db);

                new ScheduleFailure(s, se, Fixture.Today(), error).In(Db);

                var f = new ScheduleInitialisationIssuesFixture(Db);

                s.IsDeleted = true;

                await f.Subject.Prepare(Fixture.String());

                f.ExcelExporter.DidNotReceiveWithAnyArgs().Export(null);
            }

            [Fact]
            public async Task DoesNotSaveWhenThereWereNoErrors()
            {
                var f = new ScheduleInitialisationIssuesFixture(Db);

                await f.Subject.Prepare(Fixture.String());

                f.ExcelExporter.DidNotReceiveWithAnyArgs().Export(null);
            }

            [Fact]
            public async Task SavesAddendumFilesExtractedFromErrorLogs()
            {
                var guid = Guid.NewGuid();
                var error = new ErrorBuilder
                {
                    ActivityType = GetType().AssemblyQualifiedName,
                    Message = "Oh bummer!",
                    AdditionalInfo = "/someplace/with/more/detailed/logs"
                }.Build();

                var s = new Schedule().In(Db);
                var se = new ScheduleExecution(guid, s, Fixture.Today(), Fixture.String()).In(Db);

                new ScheduleFailure(s, se, Fixture.Today(), error).In(Db);

                var f = new ScheduleInitialisationIssuesFixture(Db);
                f.FileSystem.Exists("/someplace/with/more/detailed/logs").Returns(true);

                await f.Subject.Prepare(Fixture.String());

                f.CompressionHelper.Received(1)
                 .AddToArchive("addendum.zip", Arg.Is<string>(_ => _.Contains("/someplace/with/more/detailed/logs")))
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task SavesScheduleInitiaisationIssues()
            {
                var guid = Guid.NewGuid();
                var error = new ErrorBuilder
                {
                    ActivityType = GetType().AssemblyQualifiedName,
                    Message = "Oh bummer!"
                }.Build();

                var s = new Schedule().In(Db);
                var se = new ScheduleExecution(guid, s, Fixture.Today(), Fixture.String()).In(Db);

                new ScheduleFailure(s, se, Fixture.Today(), error).In(Db);

                var f = new ScheduleInitialisationIssuesFixture(Db);

                await f.Subject.Prepare(Fixture.String());

                f.ExcelExporter
                 .Received(1)
                 .Export(Arg.Is<IEnumerable<ScheduleInitialisationErrorDetails>>(_
                                                                                     => _.Single().CorrelationId == se.CorrelationId &&
                                                                                        _.Single().ScheduleExecutionId == guid &&
                                                                                        _.Single().ScheduleId == s.Id &&
                                                                                        _.Single().ScheduleName == s.Name &&
                                                                                        _.Single().Activity == GetType().FullName &&
                                                                                        _.Single().Message == "Oh bummer!"));
            }
        }

        public class ScheduleInitialisationIssuesFixture : IFixture<ScheduleInitialisationIssues>
        {
            public ScheduleInitialisationIssuesFixture(InMemoryDbContext db)
            {
                FileSystem = Substitute.For<IFileSystem>();
                FileSystem.OpenWrite(Arg.Any<string>()).Returns(new MemoryStream());
                FileSystem.AbsolutePath(Arg.Any<string>()).Returns(x => x[0]);

                CompressionHelper = Substitute.For<ICompressionHelper>();

                ExcelExporter = Substitute.For<ISimpleExcelExporter>();
                ExcelExporter.Export(null).ReturnsForAnyArgs(new MemoryStream());

                Subject = new ScheduleInitialisationIssues(db, FileSystem, CompressionHelper, ExcelExporter);
            }

            public IFileSystem FileSystem { get; set; }

            public ICompressionHelper CompressionHelper { get; set; }

            public ISimpleExcelExporter ExcelExporter { get; set; }

            public ScheduleInitialisationIssues Subject { get; }
        }
    }

    public class ErrorBuilder : IBuilder<string>
    {
        public string ActivityType { get; set; }

        public string Message { get; set; }

        public string AdditionalInfo { get; set; }

        public string Build()
        {
            var o = string.IsNullOrWhiteSpace(AdditionalInfo)
                ? new
                {
                    message = Message,
                    activityType = ActivityType
                }
                : (object) new
                {
                    message = Message,
                    activityType = ActivityType,
                    data = new
                    {
                        additionalInfo = AdditionalInfo
                    }
                };

            return JsonConvert.SerializeObject(o, Formatting.Indented);
        }
    }
}