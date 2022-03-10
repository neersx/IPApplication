using System;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.FileApp.Activities;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class DueScheduleFacts
    {
        public class ExecuteMethod : FactBase
        {
            [Fact]
            public async Task PassesOnCancellationTokenWhileStartingSchedule()
            {
                const int queryKey = 1;
                const int runAs = 2;
                var cancellationToken = Guid.NewGuid();

                var f = new DueScheduleFixture(Db)
                    .WithSchedule(queryKey, runAs, out var s);

                var r = (ActivityGroup) await f.Subject.Execute(s.Id, cancellationToken);

                f.ScheduleRuntimeEvents.Received(1).StartSchedule(Arg.Any<Schedule>(), cancellationToken);
            }
        }

        public class DueScheduleFixture : IFixture<DueSchedule>
        {
            public DueScheduleFixture(InMemoryDbContext db)
            {
                Repository = db;
                FileSystem = Substitute.For<IFileSystem>();
                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();
                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();

                Subject = new DueSchedule(Repository, FileSystem, ScheduleRuntimeEvents, DataDownloadLocationResolver);
            }

            public InMemoryDbContext Repository { get; set; }

            public IFileSystem FileSystem { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }
            public DueSchedule Subject { get; }

            public DueScheduleFixture WithSchedule(int? savedQueryId, int? runAs, out Schedule schedule)
            {
                schedule = new Schedule
                {
                    Id = 1,
                    Name = "Schedule1",
                    DataSourceType = DataSourceType.UsptoTsdr,
                    ExtendedSettings = new JObject
                    {
                        {"SavedQueryId", savedQueryId},
                        {"RunAsUserId", runAs}
                    }.ToString()
                }.In(Repository);
                return this;
            }
        }
    }
}