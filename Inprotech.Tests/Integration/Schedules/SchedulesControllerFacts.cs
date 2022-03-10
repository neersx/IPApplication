using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class SchedulesControllerFacts
    {
        public class DeleteMethod : FactBase
        {
            [Theory]
            [InlineData(DataSourceType.UsptoPrivatePair, DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.UsptoTsdr, DataSourceType.UsptoPrivatePair)]
            public void ThrowsWhenDeletingScheduleWithUnauthorisedDataSource(DataSourceType scheduleDataSource,
                                                                             DataSourceType permittedDataSource)
            {
                var scheduleToDelete = new Schedule {DataSourceType = scheduleDataSource}.In(Db);

                var f = new SchedulesControllerFixture(Db)
                    .WithAccessTo(permittedDataSource);

                var exception =
                    Record.Exception(() => { f.Subject.Delete(scheduleToDelete.Id); });

                Assert.NotNull(exception);

                Assert.Equal("Unable to delete a schedule with data source you do not have access to.",
                             exception.Message);
            }

            [Fact]
            public void DeletesChildRunOnceSchedules()
            {
                var scheduleToDelete = new Schedule {Id = 1}.In(Db);
                var childToDelete1 = new Schedule {Parent = scheduleToDelete}.In(Db);
                var childToDelete2 = new Schedule {Parent = scheduleToDelete}.In(Db);

                var f = new SchedulesControllerFixture(Db)
                    .WithAccessTo(DataSourceType.UsptoPrivatePair);

                var result = f.Subject.Delete(scheduleToDelete.Id);

                Assert.True(scheduleToDelete.IsDeleted);
                Assert.Equal(f.SystemClock(), scheduleToDelete.DeletedOn);
                Assert.Equal(f.SecurityContext.User.Id, scheduleToDelete.DeletedBy);

                Assert.True(childToDelete1.IsDeleted);
                Assert.Equal(f.SystemClock(), childToDelete1.DeletedOn);
                Assert.Equal(f.SecurityContext.User.Id, childToDelete1.DeletedBy);
                Assert.True(childToDelete2.IsDeleted);
                Assert.Equal(f.SystemClock(), childToDelete2.DeletedOn);
                Assert.Equal(f.SecurityContext.User.Id, childToDelete2.DeletedBy);

                Assert.Equal("success", result.Result);
            }

            [Fact]
            public void DeletesSchedule()
            {
                var scheduleToDelete = new Schedule().In(Db);

                var f = new SchedulesControllerFixture(Db)
                    .WithAccessTo(DataSourceType.UsptoPrivatePair);

                var result = f.Subject.Delete(scheduleToDelete.Id);

                Assert.True(scheduleToDelete.IsDeleted);
                Assert.Equal(f.SystemClock(), scheduleToDelete.DeletedOn);
                Assert.Equal(f.SecurityContext.User.Id, scheduleToDelete.DeletedBy);

                Assert.Equal("success", result.Result);
            }

            [Fact]
            public void ThrowsExceptionWhenDeletingNonExistentSchedule()
            {
                var exception =
                    Record.Exception(() => { new SchedulesControllerFixture(Db).Subject.Delete(Fixture.Integer()); });

                Assert.NotNull(exception);
                Assert.Equal("Unable to delete a non-existent schedule.", exception.Message);
            }

            [Fact]
            public void ThrowsExceptionWhenDeletingSoftDeletedSchedule()
            {
                var deletedSchedule = new Schedule
                {
                    IsDeleted = true
                }.In(Db);

                var exception =
                    Record.Exception(() => { new SchedulesControllerFixture(Db).Subject.Delete(deletedSchedule.Id); });

                Assert.NotNull(exception);
                Assert.Equal("Unable to delete a non-existent schedule.", exception.Message);
            }
        }

        public class RunNowMethod : FactBase
        {
            [Theory]
            [InlineData(DataSourceType.UsptoPrivatePair, DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.UsptoTsdr, DataSourceType.UsptoPrivatePair)]
            public void ThrowsWhenRunningAScheduleWithUnauthorisedDataSource(DataSourceType scheduleDataSource,
                                                                             DataSourceType permittedDataSource)
            {
                var scheduleToRun = new Schedule {DataSourceType = scheduleDataSource}.In(Db);

                var f = new SchedulesControllerFixture(Db)
                    .WithAccessTo(permittedDataSource);

                var exception =
                    Record.Exception(() => { f.Subject.RunNow(scheduleToRun.Id); });

                Assert.NotNull(exception);

                Assert.Equal("Unable to run a Schedule for a Data Source Type you don't have access to.",
                             exception.Message);
            }

            [Fact]
            public void SchedulesALinkedShadowCopyOfScheduleToRunNow()
            {
                var scheduleToRun = new Schedule
                {
                    Id = 99,
                    Name = "Schedule",
                    DownloadType = DownloadType.All,
                    CreatedOn = Fixture.Today(),
                    CreatedBy = Fixture.Integer(),
                    LastRunStartOn = Fixture.PastDate(),
                    NextRun = Fixture.FutureDate(),
                    DataSourceType = DataSourceType.UsptoPrivatePair,
                    ExtendedSettings = "{\"SomeThing\":\"WithAValue\"}",
                    ExpiresAfter = Fixture.Today(),
                    State = ScheduleState.Active
                }.In(Db);

                var f = new SchedulesControllerFixture(Db).WithAccessTo(DataSourceType.UsptoPrivatePair);

                var result = f.Subject.RunNow(scheduleToRun.Id);

                var rs = Db.Set<Schedule>().Last();

                Assert.NotNull(rs);
                Assert.Equal(ScheduleType.OnDemand, rs.Type);
                Assert.Equal(scheduleToRun.Name, rs.Name);
                Assert.Equal(scheduleToRun.DownloadType, rs.DownloadType);
                Assert.Equal(f.SystemClock(), rs.CreatedOn);
                Assert.Equal(f.SecurityContext.User.Id, rs.CreatedBy);
                Assert.False(rs.IsDeleted);
                Assert.Equal(f.SystemClock(), rs.NextRun);
                Assert.Equal(scheduleToRun.DataSourceType, rs.DataSourceType);
                Assert.Equal(scheduleToRun.ExtendedSettings, rs.ExtendedSettings);
                Assert.Equal(f.SystemClock(), rs.ExpiresAfter);
                Assert.Equal(scheduleToRun.Id, rs.Parent.Id);
                Assert.Equal(ScheduleState.RunNow, rs.State);

                Assert.Equal("success", result.Result);
            }

            [Fact]
            public void ThrowsExceptionWhenRunningNonExistentSchedule()
            {
                var exception =
                    Record.Exception(() => { new SchedulesControllerFixture(Db).Subject.RunNow(Fixture.Integer()); });

                Assert.NotNull(exception);
                Assert.Equal("Unable to run a non-existent schedule.", exception.Message);
            }
        }

        public class StopMethod : FactBase
        {
            [Fact]
            public async Task CallsIntegrationServerToStopExecutions()
            {
                var scheduleToStop = new Schedule {DataSourceType = DataSourceType.UsptoTsdr}.In(Db);
                dynamic[] scheduleDetails = {new {id = 1}};

                var f = new SchedulesControllerFixture(Db);
                f.IntegrationServerClient.GetResponse(Arg.Any<string>()).Returns(new HttpResponseMessage(HttpStatusCode.OK));
                f.ScheduleDetails.Get().Returns(scheduleDetails);

                var r = await f.Subject.Stop(scheduleToStop.Id);

                var apiString = $"api/schedules/stop/{scheduleToStop.Id}/{f.SecurityContext.User.Id}";
                f.IntegrationServerClient.Received(1).GetResponse(apiString).IgnoreAwaitForNSubstituteAssertion();

                f.ScheduleDetails.Received(1).Get();
                Assert.Equal("success", r.Result);
                var schedules = ((IEnumerable<dynamic>) r.Schedules).ToArray();
                Assert.Equal(scheduleDetails, schedules);
            }

            [Fact]
            public async Task ThrowsExceptionIfErrorWhileStoppingExecutions()
            {
                var scheduleToStop = new Schedule {DataSourceType = DataSourceType.UsptoTsdr}.In(Db);

                var f = new SchedulesControllerFixture(Db);
                f.IntegrationServerClient.GetResponse(Arg.Any<string>())
                 .Returns(new HttpResponseMessage(HttpStatusCode.NotAcceptable));

                var exception =
                    await Assert.ThrowsAsync<HttpRequestException>(async () => await f.Subject.Stop(scheduleToStop.Id));

                Assert.NotNull(exception);
                f.ScheduleDetails.Received(0).Get();
            }
        }
        
        public class PauseMethod : FactBase
        {
            [Fact]
            public async Task CallsIntegrationServerToPauseExecutions()
            {
                var scheduleToStop = new Schedule {DataSourceType = DataSourceType.UsptoTsdr, Type = ScheduleType.Continuous }.In(Db);
                dynamic[] scheduleDetails = {new {id = 1}};

                var f = new SchedulesControllerFixture(Db);
                f.IntegrationServerClient.GetResponse(Arg.Any<string>()).Returns(new HttpResponseMessage(HttpStatusCode.OK));
                f.ScheduleDetails.Get().Returns(scheduleDetails);

                var r = await f.Subject.Pause(scheduleToStop.Id);
                f.ScheduleDetails.Received(1).Get();
                Assert.Equal("success", r.Result);
                var schedules = ((IEnumerable<dynamic>) r.Schedules).ToArray();
                Assert.Equal(scheduleDetails, schedules);
                Assert.Equal(scheduleToStop.State, ScheduleState.Paused);
            }
        }

        public class ResumeMethod : FactBase
        {
            [Fact]
            public async Task CallsIntegrationServerToResumeExecutions()
            {
                var scheduleToStop = new Schedule {DataSourceType = DataSourceType.UsptoTsdr, Type = ScheduleType.Continuous }.In(Db);
                dynamic[] scheduleDetails = {new {id = 1}};

                var f = new SchedulesControllerFixture(Db);
                f.IntegrationServerClient.GetResponse(Arg.Any<string>()).Returns(new HttpResponseMessage(HttpStatusCode.OK));
                f.ScheduleDetails.Get().Returns(scheduleDetails);

                var r = await f.Subject.Resume(scheduleToStop.Id);
                f.ScheduleDetails.Received(1).Get();
                Assert.Equal("success", r.Result);
                var schedules = ((IEnumerable<dynamic>) r.Schedules).ToArray();
                Assert.Equal(scheduleDetails, schedules);
                Assert.Equal(scheduleToStop.State, ScheduleState.Active);
            }
        }

        public class SchedulesControllerFixture : IFixture<SchedulesController>
        {
            readonly InMemoryDbContext _db;

            public SchedulesControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new User("fee-earner", false));

                AvailableDataSources = Substitute.For<IAvailableDataSources>();

                ScheduleDetails = Substitute.For<IScheduleDetails>();

                IntegrationServerClient = Substitute.For<IIntegrationServerClient>();

                SystemClock = Fixture.Today;
            }

            public IAvailableDataSources AvailableDataSources { get; }

            public ISecurityContext SecurityContext { get; }

            public IScheduleDetails ScheduleDetails { get; }

            public IIntegrationServerClient IntegrationServerClient { get; }

            public Func<DateTime> SystemClock { get; }

            public SchedulesController Subject => new SchedulesController(
                                                                          _db,
                                                                          SecurityContext,
                                                                          AvailableDataSources,
                                                                          IntegrationServerClient,
                                                                          ScheduleDetails,
                                                                          SystemClock);

            public SchedulesControllerFixture WithAccessTo(DataSourceType dataSourceType)
            {
                AvailableDataSources.List().Returns(new[] {dataSourceType});
                return this;
            }
        }
    }
}