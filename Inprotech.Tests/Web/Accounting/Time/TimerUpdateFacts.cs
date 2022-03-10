using System;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Time.Timers;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimerUpdateFacts
    {
        public class StartTimer
        {
            [Fact]
            public async Task ThrowsExceptionIfInvalidInput()
            {
                var f = new TimerUpdateFixture();
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.StartTimerFor(10, null));
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.StartTimerFor(10, new TimerSeed()));
            }

            [Fact]
            public async Task DefaultsValuesIfCaseKeyIsProvided()
            {
                var input = new TimerSeed {CaseKey = 10, StaffNameId = 10, StartDateTime = Fixture.TodayTime()};

                var f = new TimerUpdateFixture();
                var wipDefaults = new WipDefaults {WIPTemplateKey = "santa", NarrativeKey = 28, NarrativeText = "Santa in the town!"};
                f.WipDefaulting.ForCase(Arg.Any<WipTemplateFilterCriteria>(),Arg.Any<int>()).ReturnsForAnyArgs(wipDefaults);
                var addedEntry = new TimeEntry {EntryNo = 100, StaffId = input.StaffNameId.Value};
                f.DiaryUpdate.AddEntry(Arg.Any<RecordableTime>()).ReturnsForAnyArgs(addedEntry);

                var result = await f.Subject.StartTimerFor(10, input);
                f.DiaryUpdate.Received(1).AddEntry(Arg.Is<RecordableTime>(_ => _.StaffId == input.StaffNameId && _.Start == input.StartDateTime && _.CaseKey == input.CaseKey
                                                                               && _.Activity == wipDefaults.WIPTemplateKey && _.NarrativeNo == wipDefaults.NarrativeKey && _.NarrativeText == wipDefaults.NarrativeText
                                                                               && _.Finish == null && _.isTimer && _.EntryDate == input.StartDateTime.Value.Date)).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(addedEntry.EntryNo, result.EntryNo);
                Assert.Equal(addedEntry.StaffId, result.EmployeeNo);
            }
        }

        public class StopTimerFor
        {
            [Fact]
            public async Task CallsDiaryTimerUpdateToStopTimer()
            {
                IQueryable<Diary> q = new InMemoryDbContext().Set<Diary>();
                var expectedResult = new DiaryKeyDetails(10, 199);
                var f = new TimerUpdateFixture();
                f.TimesheetList.GetRunningTimersFor(Arg.Any<int>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(q);
                f.DiaryTimerUpdater.StopTimerEntry(Arg.Any<IQueryable<Diary>>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(Task.FromResult(expectedResult));
                var stopTime = Fixture.Today().AddHours(1).AddMinutes(30);
                var result = await f.Subject.StopTimerFor(10, stopTime);

                f.TimesheetList.Received(1).GetRunningTimersFor(10, stopTime.Date);
                f.DiaryTimerUpdater.Received(1).StopTimerEntry(Arg.Do<IQueryable<Diary>>(p => Assert.Equal(q.OrderByDescending(_ => _.StartTime).Take(1).ToArray(), p.ToArray())), stopTime).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(expectedResult, result);
            }
        }

        public class StopPrevTimer
        {
            [Fact]
            public async Task CallsDiaryUpdate()
            {
                IQueryable<Diary> q = new InMemoryDbContext().Set<Diary>();
                var expectedResult = new DiaryKeyDetails(10, 199);
                var f = new TimerUpdateFixture();
                f.TimesheetList.GetRunningTimersFor(Arg.Any<int>()).ReturnsForAnyArgs(q);
                f.DiaryTimerUpdater.UpdateTimeForTimerEntry(Arg.Any<IQueryable<Diary>>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(Task.FromResult(expectedResult));

                var result = await f.Subject.StopPrevTimer(10);

                f.TimesheetList.Received(1).GetRunningTimersFor(10);
                f.DiaryTimerUpdater.Received(1).UpdateTimeForTimerEntry(Arg.Do<IQueryable<Diary>>(p => Assert.Equal(q.OrderByDescending(_ => _.StartTime).Take(1).ToArray(), p.ToArray()))).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(expectedResult, result);
            }
        }

        public class UpdateTimer
        {
            [Fact]
            public async Task ThrowsExceptionIfInvalidInput()
            {
                var f = new TimerUpdateFixture();

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.UpdateTimer(new RecordableTime {StaffId = null}));
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.UpdateTimer(new RecordableTime {StaffId = 1, EntryNo = null}));

                f.DiaryUpdate.DidNotReceive().UpdateEntry(Arg.Any<RecordableTime>()).IgnoreAwaitForNSubstituteAssertion();
                f.DiaryTimerUpdater.DidNotReceive().UpdateTimeForTimerEntry(Arg.Any<IQueryable<Diary>>(), Arg.Any<DateTime?>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(false, true)]
            [InlineData(true, false)]
            [InlineData(true, true)]
            public async Task CallsToStopTimer(bool stopTime, bool updateTime)
            {
                var input = new RecordableTime {StaffId = 1, EntryNo = 99, TotalTime = new DateTime(1899, 1, 1, 1, 0, 0)};

                var f = new TimerUpdateFixture();

                f.DiaryUpdate.UpdateEntry(Arg.Any<RecordableTime>()).ReturnsForAnyArgs(Task.FromResult(new TimeEntry() {EntryNo = 99, StaffId = 1}));
                f.DiaryTimerUpdater.UpdateTimeForTimerEntry(Arg.Any<IQueryable<Diary>>(), Arg.Any<DateTime?>()).ReturnsForAnyArgs(Task.FromResult(new DiaryKeyDetails(1, 99)));
                f.DiaryTimerUpdater.UpdateTimeAndDataForTimerEntry(Arg.Any<RecordableTime>(), Arg.Any<DateTime?>()).ReturnsForAnyArgs(Task.FromResult(new DiaryKeyDetails(1, 99)));
                var result = await f.Subject.UpdateTimer(input, stopTime, updateTime);

                if (updateTime && stopTime)
                {
                    f.DiaryTimerUpdater.Received(1).UpdateTimeAndDataForTimerEntry(input, input.TotalTime).IgnoreAwaitForNSubstituteAssertion();
                }
                else
                {
                    f.DiaryUpdate.Received(updateTime ? 1 : 0).UpdateEntry(input).IgnoreAwaitForNSubstituteAssertion();
                    f.DiaryTimerUpdater.Received(stopTime ? 1 : 0).UpdateTimeForTimerEntry(Arg.Any<IQueryable<Diary>>(), Arg.Any<DateTime?>()).IgnoreAwaitForNSubstituteAssertion();
                }

                if (updateTime)
                {
                    f.TimesheetList.GetRunningTimersFor(input.StaffId.Value, null, input.EntryNo);
                }

                Assert.Equal(input.EntryNo, result.EntryNo);
                Assert.Equal(input.StaffId, result.EmployeeNo);
            }
        }

        public class ResetTimer
        {
            [Fact]
            public async Task ThrowsExceptionIfInvalidInput()
            {
                var f = new TimerUpdateFixture();

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.ResetTimer(new RecordableTime {StaffId = null}));
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.ResetTimer(new RecordableTime {StaffId = 1, EntryNo = null}));
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.ResetTimer(new RecordableTime {StaffId = 1, EntryNo = 11, Start = null}));

                f.DiaryTimerUpdater.DidNotReceive().ResetTimeForTimerEntry(Arg.Any<IQueryable<Diary>>(), Arg.Any<DateTime>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task CallsToResetTimer()
            {
                var input = new RecordableTime {StaffId = 1, EntryNo = 90, TotalTime = new DateTime(1899, 1, 1, 1, 0, 0), Start = Fixture.Today()};

                var f = new TimerUpdateFixture();
                var output = new DiaryKeyDetails(input.StaffId.Value, input.EntryNo.Value);
                f.DiaryTimerUpdater.ResetTimeForTimerEntry(Arg.Any<IQueryable<Diary>>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(Task.FromResult(output));
                var result = await f.Subject.ResetTimer(input);

                f.TimesheetList.GetRunningTimersFor(input.StaffId.Value, null, input.EntryNo);
                f.DiaryTimerUpdater.Received(1).ResetTimeForTimerEntry(Arg.Any<IQueryable<Diary>>(), input.Start.Value).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(input.EntryNo, result.EntryNo);
                Assert.Equal(input.StaffId, result.EmployeeNo);
            }
        }

        public class ContinueTimer
        {
            [Fact]
            public async Task ThrowsExceptionIfInvalidInput()
            {
                var f = new TimerUpdateFixture();

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.ContinueTimer(new TimerSeed {StaffNameId = null}));
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.ContinueTimer(new TimerSeed {StaffNameId = 1, ContinueFromEntryNo = null}));

                f.DiaryUpdate.DidNotReceive().AddEntry(Arg.Any<RecordableTime>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task CallsDiaryUpdateWithCorrectData()
            {
                var f = new TimerUpdateFixture();
                var db = new InMemoryDbContext();
                
                var q = db.Set<Diary>();
                f.TimesheetList.DiaryFor(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(q);
                f.DiaryUpdate.AddEntry(Arg.Any<RecordableTime>()).ReturnsForAnyArgs(Task.FromResult(new TimeEntry() {EntryNo = 1, StaffId = 99}));

                var seed = new TimerSeed {StaffNameId = 1, ContinueFromEntryNo = 99, StartDateTime = Fixture.Today().AddHours(1)};
                await f.Subject.ContinueTimer(seed);
                f.DiaryTimerUpdater.Received(1).AddContinuedTimerEntry(Arg.Is<int>(_ => _ == seed.StaffNameId), Arg.Is<int>(_ => _ == seed.ContinueFromEntryNo), Arg.Is<DateTime>(_ => _ == seed.StartDateTime)).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class TimerUpdateFixture : IFixture<TimerUpdate>
        {
            public TimerUpdateFixture()
            {
                Now = Substitute.For<Func<DateTime>>();
                Now().Returns(Fixture.Today());
                TimesheetList = Substitute.For<ITimesheetList>();
                TimesheetList = Substitute.For<ITimesheetList>();

                var m = new Mapper(new MapperConfiguration(cfg =>
                {
                    cfg.AddProfile(new AccountingProfile());
                    cfg.CreateMissingTypeMaps = true;
                }));
                Mapper = m.DefaultContext.Mapper.DefaultContext.Mapper;

                WipDefaulting = Substitute.For<IWipDefaulting>();

                DiaryUpdate = Substitute.For<IDiaryUpdate>();

                DiaryTimerUpdater = Substitute.For<IDiaryTimerUpdater>();

                Subject = new TimerUpdate(TimesheetList, WipDefaulting, DiaryTimerUpdater, DiaryUpdate);
            }

            public Func<DateTime> Now { get; }
            public IWipDefaulting WipDefaulting { get; }

            public ITimesheetList TimesheetList { get; }
            public IDiaryUpdate DiaryUpdate { get; }
            public IDiaryTimerUpdater DiaryTimerUpdater { get; }
            public IMapper Mapper { get; }
            public TimerUpdate Subject { get; }
        }
    }
}