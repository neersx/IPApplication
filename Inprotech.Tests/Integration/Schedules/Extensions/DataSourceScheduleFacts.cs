using System;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure;
using Inprotech.Integration;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules.Extensions
{
    public class DataSourceScheduleFacts
    {
        public class TryCreateFromMethod : FactBase
        {
            [Theory]
            [InlineData(DataSourceType.UsptoPrivatePair, DataSourceType.UsptoTsdr)]
            [InlineData(DataSourceType.UsptoTsdr, DataSourceType.UsptoPrivatePair)]
            public async Task ValidatesSecurity(DataSourceType scheduleDataSource, DataSourceType permittedDataSource)
            {
                var f = new DataSourceScheduleFixture(Db)
                    .WithAccessTo(permittedDataSource);

                var result = await f.Subject.TryCreateFrom(ValidScheduleRequest(scheduleDataSource));

                Assert.Equal("unauthorised-schedule-datasource", result.ValidationResult);
                Assert.False(result.IsValid);
            }

            static JObject ValidScheduleRequest(DataSourceType dataSourceType)
            {
                return new JObject
                {
                    {"DataSource", dataSourceType.ToString()},
                    {"Name", "same name"},
                    {"RunOnDays", "Mon"},
                    {"RunOnce", "false"},
                    {"DownloadType", "All"},
                    {"StartTime", TimeSpan.FromHours(4)},
                    {"ExpiresAfter", Fixture.FutureDate()}
                };
            }

            [Fact]
            public async Task FindsMatchingScheduleCreator()
            {
                var tsdr = Substitute.For<ICreateSchedule>();
                tsdr.TryCreateFrom(Arg.Any<JObject>())
                    .ReturnsForAnyArgs(new DataSourceScheduleResult
                    {
                        Schedule = new Schedule()
                    });

                var privatePair = Substitute.For<ICreateSchedule>();

                var f = new DataSourceScheduleFixture(Db)
                        .WithCreateScheduleFor(DataSourceType.UsptoTsdr, tsdr)
                        .WithCreateScheduleFor(DataSourceType.UsptoPrivatePair, privatePair)
                        .WithAccessTo(DataSourceType.UsptoTsdr);

                var _ = await f.Subject.TryCreateFrom(ValidScheduleRequest(DataSourceType.UsptoTsdr));

                tsdr.Received(1).TryCreateFrom(Arg.Any<JObject>()).IgnoreAwaitForNSubstituteAssertion();
                privatePair.DidNotReceive().TryCreateFrom(Arg.Any<JObject>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task PopulatesRunOnceLaterScheduleData()
            {
                var tsdr = Substitute.For<ICreateSchedule>();
                tsdr.TryCreateFrom(Arg.Any<JObject>())
                    .ReturnsForAnyArgs(new DataSourceScheduleResult
                    {
                        Schedule = new Schedule()
                    });

                var f = new DataSourceScheduleFixture(Db)
                        .WithCreateScheduleFor(DataSourceType.UsptoTsdr, tsdr)
                        .WithAccessTo(DataSourceType.UsptoTsdr);

                var request = ValidScheduleRequest(DataSourceType.UsptoTsdr);
                request["Recurrence"] = (int) DataSourceSchedule.Recurrence.RunOnce;
                request["RunNow"] = false;
                request["RunOn"] = Fixture.FutureDate();

                var result = await f.Subject.TryCreateFrom(request);

                var s = result.Schedule;

                Assert.True(result.IsValid);
                Assert.Equal(s.NextRun, DateTime.Parse(request["RunOn"].ToString()) + TimeSpan.Parse(request["StartTime"].ToString()));
            }

            [Fact]
            public async Task PopulatesRunOnceNowScheduleData()
            {
                var tsdr = Substitute.For<ICreateSchedule>();
                tsdr.TryCreateFrom(Arg.Any<JObject>())
                    .ReturnsForAnyArgs(new DataSourceScheduleResult
                    {
                        Schedule = new Schedule()
                    });

                var f = new DataSourceScheduleFixture(Db)
                        .WithCreateScheduleFor(DataSourceType.UsptoTsdr, tsdr)
                        .WithAccessTo(DataSourceType.UsptoTsdr);

                var request = ValidScheduleRequest(DataSourceType.UsptoTsdr);
                request["Recurrence"] = (int) DataSourceSchedule.Recurrence.RunOnce;
                request["RunNow"] = true;

                var r = await f.Subject.TryCreateFrom(request);

                var s = r.Schedule;

                Assert.True(r.IsValid);
                Assert.Equal(s.CreatedOn, s.NextRun);
            }

            [Fact]
            public async Task PopulatesScheduleEssentials()
            {
                var tsdr = Substitute.For<ICreateSchedule>();
                tsdr.TryCreateFrom(Arg.Any<JObject>())
                    .ReturnsForAnyArgs(new DataSourceScheduleResult
                    {
                        Schedule = new Schedule()
                    });

                var f = new DataSourceScheduleFixture(Db)
                        .WithCreateScheduleFor(DataSourceType.UsptoTsdr, tsdr)
                        .WithAccessTo(DataSourceType.UsptoTsdr);

                var request = ValidScheduleRequest(DataSourceType.UsptoTsdr);

                var r = await f.Subject.TryCreateFrom(request);

                var s = r.Schedule;

                Assert.True(r.IsValid);
                Assert.Equal(s.Name, request["Name"]);
                Assert.Equal(s.DataSourceType.ToString(), request["DataSource"]);
                Assert.Equal(s.DownloadType.ToString(), request["DownloadType"]);
                Assert.Equal(s.StartTime, request["StartTime"]);
                Assert.Equal(s.RunOnDays, request["RunOnDays"]);
                Assert.Equal(s.CreatedOn, Fixture.Today());
                Assert.Equal(s.CreatedBy, f.SecurityContext.User.Id);
                Assert.Equal(s.ExpiresAfter, request["ExpiresAfter"]);

                f.PopulateNextRun.Received(1).For(s);
            }

            [Fact]
            public async Task RelaysSpecificCreatorsValidationError()
            {
                var tsdr = Substitute.For<ICreateSchedule>();
                tsdr.TryCreateFrom(Arg.Any<JObject>())
                    .ReturnsForAnyArgs(new DataSourceScheduleResult
                    {
                        ValidationResult = "tsdr-error"
                    });

                var f = new DataSourceScheduleFixture(Db)
                        .WithCreateScheduleFor(DataSourceType.UsptoTsdr, tsdr)
                        .WithAccessTo(DataSourceType.UsptoTsdr);

                var r = await f.Subject.TryCreateFrom(ValidScheduleRequest(DataSourceType.UsptoTsdr));

                Assert.Equal("tsdr-error", r.ValidationResult);
                Assert.False(r.IsValid);
            }

            [Fact]
            public async Task ValidatesDuplicateScheduleNames()
            {
                new Schedule
                {
                    Name = "same name"
                }.In(Db);

                var f = new DataSourceScheduleFixture(Db)
                    .WithAccessTo(DataSourceType.UsptoPrivatePair);

                var result = await f.Subject.TryCreateFrom(new JObject
                {
                    {"DataSource", DataSourceType.UsptoPrivatePair.ToString()},
                    {"Name", "same name"},
                    {"RunOnDays", "Mon"}
                });

                Assert.Equal("duplicate-schedule-name", result.ValidationResult);
            }

            [Fact]
            public async Task ValidatesRunOnDays()
            {
                var f = new DataSourceScheduleFixture(Db)
                    .WithAccessTo(DataSourceType.UsptoPrivatePair);

                var result = await f.Subject.TryCreateFrom(new JObject
                {
                    {"DataSource", DataSourceType.UsptoPrivatePair.ToString()},
                    {"Name", "a"},
                    {"RunOnDays", string.Empty}
                });

                Assert.Equal("invalid-run-on-days", result.ValidationResult);
            }

            [Fact]
            public async Task ValidatesScheduleName()
            {
                var f = new DataSourceScheduleFixture(Db)
                    .WithAccessTo(DataSourceType.UsptoPrivatePair);

                var result = await f.Subject.TryCreateFrom(new JObject
                {
                    {"DataSource", DataSourceType.UsptoPrivatePair.ToString()},
                    {"Name", string.Empty}
                });

                Assert.Equal("invalid-schedule-name", result.ValidationResult);
            }

            [Fact]
            public async Task ValidatesBackroundProcessLoginId()
            {
                var f = new DataSourceScheduleFixture(Db)
                    .WithAccessTo(DataSourceType.UsptoPrivatePair);
                f.SetBackgroundProcessLoginId(string.Empty);

                var result = await f.Subject.TryCreateFrom(new JObject
                {
                    {"DataSource", DataSourceType.UsptoPrivatePair.ToString()},
                    {"Name", Fixture.String()},
                    {"RunOnDays", "Mon"}
                });

                Assert.Equal("background-process-loginid", result.ValidationResult);
            }
        }

        public class ViewMethod : FactBase
        {
            public ViewMethod()
            {
                _schedule = new Schedule
                {
                    Name = "schedule"
                }.In(Db);
            }

            readonly Schedule _schedule;

            [Fact]
            public void ReturnsTheSchedule()
            {
                _schedule.DataSourceType = DataSourceType.UsptoPrivatePair;
                _schedule.DownloadType = DownloadType.Documents;
                _schedule.RunOnDays = "Sun,Mon,Tue";
                _schedule.StartTime = TimeSpan.FromHours(4);
                _schedule.NextRun = Fixture.FutureDate();
                _schedule.ExtendedSettings = new JObject
                {
                    {"customerNumbers", "70859"}
                }.ToString();

                var fixture = new DataSourceScheduleFixture(Db);
                var r = fixture.Subject.View(_schedule);

                Assert.Equal(_schedule.Name, r.Name);
                Assert.Equal(_schedule.DataSourceType.ToString(), r.DataSource);
                Assert.Equal(_schedule.DownloadType.ToString(), r.DownloadType);
                Assert.Equal(_schedule.RunOnDays, r.RunOnDays);
                Assert.Equal(_schedule.StartTime, r.StartTime);
                Assert.Equal(_schedule.NextRun, r.NextRun);
                Assert.Equal("70859", r.Extension.customerNumbers.ToString());
            }
        }

        public class ViewMultipleMethod : FactBase
        {
            public ViewMultipleMethod()
            {
                _schedule = new Schedule
                {
                    Name = "schedule"
                }.In(Db);

                _shortlistedSchedules = Db.Set<Schedule>().Where(_ => _.Id == _schedule.Id);
            }

            readonly Schedule _schedule;
            readonly IQueryable<Schedule> _shortlistedSchedules;

            [Fact]
            public void ReturnEmptyStatusIfNoScheduleExecution()
            {
                var fixture = new DataSourceScheduleFixture(Db);
                var r = fixture.Subject.View(_shortlistedSchedules).Single();

                Assert.Equal(string.Empty, r.ExecutionStatus);
            }

            [Fact]
            public void ReturnRunningStatusIfAnyScheduleExecutionRunning()
            {
                new ScheduleExecutionBuilder(Db)
                {
                    Finished = Fixture.Today(),
                    ScheduleId = _schedule.Id,
                    Status = ScheduleExecutionStatus.Complete
                }.Build();

                new ScheduleExecutionBuilder(Db)
                {
                    ScheduleId = _schedule.Id,
                    Status = ScheduleExecutionStatus.Started
                }.Build();

                var fixture = new DataSourceScheduleFixture(Db);
                var r = fixture.Subject.View(_shortlistedSchedules).Single();

                Assert.Equal("Started", r.ExecutionStatus.ToString());
            }

            [Fact]
            public void ReturnsScheduleWithTheLastExecutionRunStatus()
            {
                new ScheduleExecutionBuilder(Db)
                {
                    Finished = DateTime.Now,
                    ScheduleId = _schedule.Id,
                    Status = ScheduleExecutionStatus.Complete
                }.Build();

                new ScheduleExecutionBuilder(Db)
                {
                    Finished = DateTime.Now.AddDays(-1),
                    ScheduleId = _schedule.Id,
                    Status = ScheduleExecutionStatus.Failed
                }.Build();

                _schedule.DataSourceType = DataSourceType.UsptoPrivatePair;
                _schedule.DownloadType = DownloadType.Documents;
                _schedule.RunOnDays = "Sun,Mon,Tue";
                _schedule.StartTime = TimeSpan.FromHours(4);
                _schedule.NextRun = Fixture.FutureDate();
                _schedule.ExtendedSettings = new JObject
                {
                    {"customerNumbers", "70859"}
                }.ToString();

                var fixture = new DataSourceScheduleFixture(Db);
                var r = fixture.Subject.View(_shortlistedSchedules).Single();

                Assert.Equal(_schedule.Name, r.Name);
                Assert.Equal(_schedule.DataSourceType.ToString(), r.DataSource);
                Assert.Equal(_schedule.DownloadType.ToString(), r.DownloadType);
                Assert.Equal(_schedule.RunOnDays, r.RunOnDays);
                Assert.Equal(_schedule.StartTime, r.StartTime);
                Assert.Equal(_schedule.NextRun, r.NextRun);
                Assert.Equal("70859", r.Extension.customerNumbers.ToString());

                Assert.Equal("Complete", r.ExecutionStatus.ToString());
            }
        }

        public class DataSourceScheduleFixture : IFixture<DataSourceSchedule>
        {
            public DataSourceScheduleFixture(InMemoryDbContext db)
            {
                CreateScheduleList = Substitute.For<IIndex<DataSourceType, Func<ICreateSchedule>>>();

                PopulateNextRun = Substitute.For<IPopulateNextRun>();

                AvailableDataSources = Substitute.For<IAvailableDataSources>();

                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new User("internal", false));

                SystemClock = Substitute.For<Func<DateTime>>();
                SystemClock().Returns(Fixture.Today());

                SiteControlReader = Substitute.For<ISiteControlReader>();
                SetBackgroundProcessLoginId(Fixture.String());

                Subject = new DataSourceSchedule(CreateScheduleList, db,
                                                 AvailableDataSources, PopulateNextRun, SecurityContext, SystemClock, SiteControlReader);
            }

            public IIndex<DataSourceType, Func<ICreateSchedule>> CreateScheduleList { get; }

            public IPopulateNextRun PopulateNextRun { get; set; }

            public IAvailableDataSources AvailableDataSources { get; set; }

            public ISecurityContext SecurityContext { get; set; }
            public ISiteControlReader SiteControlReader { get; }

            public Func<DateTime> SystemClock { get; set; }

            public DataSourceSchedule Subject { get; }

            public DataSourceScheduleFixture WithCreateScheduleFor(DataSourceType name, ICreateSchedule scheduleCreator)
            {
                CreateScheduleList[name].Returns(() => scheduleCreator);
                return this;
            }

            public DataSourceScheduleFixture WithAccessTo(params DataSourceType[] permittedDataSources)
            {
                AvailableDataSources.List().Returns(permittedDataSources);
                return this;
            }

            public void SetBackgroundProcessLoginId(string backgroundProcessLoginId)
            {
                SiteControlReader.Read<string>(SiteControls.BackgroundProcessLoginId).Returns(backgroundProcessLoginId);
            }
        }
    }

    public class ScheduleExecutionBuilder : IBuilder<ScheduleExecution>
    {
        readonly InMemoryDbContext _db;

        public ScheduleExecutionBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public DateTime? Finished { get; set; }

        public int ScheduleId { get; set; }

        public ScheduleExecutionStatus Status { get; set; }

        public ScheduleExecution Build()
        {
            var schedule = _db.Set<Schedule>().Single(_ => _.Id == ScheduleId);

            var scheduleExecution = new ScheduleExecution
            {
                Finished = Finished,
                ScheduleId = ScheduleId,
                Schedule = schedule,
                Status = Status
            }.In(_db);

            schedule.Executions.Add(scheduleExecution);

            return scheduleExecution;
        }
    }
}