using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Time.Timers;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Messages;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimerControllerFacts
    {
        public class StartTimer : FactBase
        {
            [Fact]
            public async Task ChecksFunctionSecurity()
            {
                var f = new TimerControllerFixture(Db);
                f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int?>()).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.StartTimer(new TimerSeed()));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                Db.DidNotReceive().Set<Diary>();
                await Db.DidNotReceive().SaveChangesAsync();
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task CallsTimerUpdateToStopAndStartTimers()
            {
                var f = new TimerControllerFixture(Db);
                var stoppedTimer = new DiaryKeyDetails(f.CurrentStaffId, 10);
                var startedTimer = new DiaryKeyDetails(f.CurrentStaffId, 11);
                var stoppedEntry = Substitute.ForPartsOf<TimeEntry>();
                stoppedEntry.EntryNo = 10;
                var startedEntry = Substitute.ForPartsOf<TimeEntry>();
                startedEntry.EntryNo = 11;
                f.TimerUpdate.StopTimerFor(Arg.Any<int>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(stoppedTimer);
                f.TimerUpdate.StartTimerFor(Arg.Any<int>(), Arg.Any<TimerSeed>()).ReturnsForAnyArgs(startedTimer);
                f.TimesheetList.Get(Arg.Any<int>(), Arg.Any<IQueryable<Diary>>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<TimeEntry>() {startedEntry, stoppedEntry});

                var input = new TimerSeed {StaffNameId = f.CurrentStaffId, StartDateTime = Fixture.Today().AddHours(Fixture.Short(23))};
                var result = await f.Subject.StartTimer(input);

                f.TimerUpdate.Received(1).StopTimerFor(Arg.Is<int>(_ => _ == f.CurrentStaffId), Arg.Is<DateTime>(_ => _ == input.StartDateTime)).IgnoreAwaitForNSubstituteAssertion();
                f.TimerUpdate.Received(1).StartTimerFor(Arg.Is<int>(_ => _ == f.CurrentStaffId), Arg.Is<TimerSeed>(_ => _.Equals(input))).IgnoreAwaitForNSubstituteAssertion();
                f.TimesheetList.Received(1).Get(f.CurrentStaffId, null, Arg.Is<int[]>(_ => _.Contains(10) && _.Contains(11))).IgnoreAwaitForNSubstituteAssertion();
                startedEntry.Received(1).MakeUiReady();
                stoppedEntry.Received(1).MakeUiReady();

                Assert.Equal(startedEntry.MakeUiReady(), result.StartedTimer);
                Assert.Equal(stoppedEntry.MakeUiReady(), result.StoppedTimer);
            }

            [Fact]
            public async Task PublishesMessageOnlyIfStartedForCurrentUser()
            {
                var f = new TimerControllerFixture(Db);
                var startedTimer = new DiaryKeyDetails(f.CurrentStaffId, 11);
                var startedEntry = Substitute.ForPartsOf<TimeEntry>();
                startedEntry.EntryNo = 11;
                startedEntry.StaffId = f.CurrentStaffId;
                startedEntry.StartTime = new DateTime();
                startedEntry.IsTimer = true;

                f.TimerUpdate.StartTimerFor(Arg.Any<int>(), Arg.Any<TimerSeed>()).ReturnsForAnyArgs(startedTimer);
                f.TimesheetList.Get(Arg.Any<int>(), Arg.Any<IQueryable<Diary>>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<TimeEntry> {startedEntry});

                var input = new TimerSeed {StaffNameId = f.CurrentStaffId, StartDateTime = Fixture.Today().AddHours(Fixture.Short(23))};
                await f.Subject.StartTimer(input);

                f.TimesheetList.Received(1).Get(f.CurrentStaffId, null, Arg.Is<int[]>(_ => _.Contains(11))).IgnoreAwaitForNSubstituteAssertion();
                startedEntry.Received(1).MakeUiReady();
                f.Bus.Received(1).Publish(Arg.Is<BroadcastMessageToClient>(x => x.Topic.StartsWith("time.recording.timerStarted") && ((TimerStateInfo) x.Data).BasicDetails.MakeUiReady() == startedEntry));
            }
        }

        public class StopTimer : FactBase
        {
            [Fact]
            public async Task ReturnsExceptionWhenNoTimeEntrySpecified()
            {
                var f = new TimerControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Stop(null));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.DidNotReceive().For(Arg.Any<int>(), Arg.Any<int>());
                await f.TimerUpdate.DidNotReceive().UpdateTimer(Arg.Any<RecordableTime>());
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ReturnsExceptionWhenNoEntryNoSpecified()
            {
                var input = new RecordableTime();
                var f = new TimerControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Stop(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.DidNotReceive().For(Arg.Any<int>(), Arg.Any<int>());
                await f.TimerUpdate.DidNotReceive().UpdateTimer(Arg.Any<RecordableTime>());
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ChecksWipWarningsBeforeSave()
            {
                var input = new RecordableTime
                {
                    EntryNo = Fixture.Integer(),
                    CaseKey = Fixture.Integer(),
                    NameKey = Fixture.Integer()
                };
                var f = new TimerControllerFixture(Db);
                f.WipWarningCheck.For(input.CaseKey, input.NameKey).Throws(new HttpResponseException(HttpStatusCode.BadRequest));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Stop(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.Received(1).For(input.CaseKey, input.NameKey);
                await f.TimerUpdate.DidNotReceive().UpdateTimer(Arg.Any<RecordableTime>());
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ReturnsWhenUpdateIsSuccessful()
            {
                var f = new TimerControllerFixture(Db);

                var input = new RecordableTime
                {
                    EntryNo = Fixture.Integer(),
                    CaseKey = Fixture.Integer(),
                    NameKey = Fixture.Integer(),
                    Start = Fixture.Today().AddHours(8),
                    TotalTime = Fixture.BaseDate().AddMinutes(10)
                };
                var startedEntry = Substitute.ForPartsOf<TimeEntry>();
                startedEntry.EntryNo = input.EntryNo;
                startedEntry.StaffId = f.CurrentStaffId;
                startedEntry.StartTime = new DateTime();
                startedEntry.IsTimer = false;

                f.TimerUpdate.UpdateTimer(Arg.Any<RecordableTime>(), Arg.Any<bool>(), Arg.Any<bool>()).Returns(Task.FromResult(new DiaryKeyDetails(f.CurrentStaffId, input.EntryNo.Value)));
                f.TimesheetList.Get(Arg.Any<int>(), Arg.Any<IQueryable<Diary>>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<TimeEntry> {startedEntry});

                var result = await f.Subject.Stop(input);
                await f.WipWarningCheck.Received(1).For(input.CaseKey, input.NameKey);
                await f.TimerUpdate.Received(1).UpdateTimer(input, true, false);
                f.Bus.Received(1).Publish(Arg.Is<BroadcastMessageToClient>(x => x.Topic.StartsWith("time.recording.timerStarted") && ((TimerStateInfo) x.Data).BasicDetails.MakeUiReady() == startedEntry));
                Assert.Equal(input.EntryNo, result.Response.EntryNo);
            }
        }

        public class SaveTimer : FactBase
        {
            [Fact]
            public async Task ReturnsExceptionWhenNoTimeEntrySpecified()
            {
                var f = new TimerControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Save(null));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.DidNotReceive().For(Arg.Any<int>(), Arg.Any<int>());
                await f.TimerUpdate.DidNotReceive().UpdateTimer(Arg.Any<RecordableTime>());
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ReturnsExceptionWhenNoEntryNoSpecified()
            {
                var input = new RecordableTime();
                var f = new TimerControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Save(new SaveTimerData {TimeEntry = input}));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.DidNotReceive().For(Arg.Any<int>(), Arg.Any<int>());
                await f.TimerUpdate.DidNotReceive().UpdateTimer(Arg.Any<RecordableTime>());
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ChecksWipWarningsBeforeSave()
            {
                var input = new RecordableTime
                {
                    EntryNo = Fixture.Integer(),
                    CaseKey = Fixture.Integer(),
                    NameKey = Fixture.Integer()
                };
                var f = new TimerControllerFixture(Db);
                f.WipWarningCheck.For(input.CaseKey, input.NameKey).Throws(new HttpResponseException(HttpStatusCode.BadRequest));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Save(new SaveTimerData {TimeEntry = input, StopTimer = false}));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.Received(1).For(input.CaseKey, input.NameKey);
                await f.TimerUpdate.DidNotReceive().UpdateTimer(Arg.Any<RecordableTime>());
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task CallsToSaveEntryWithoutStopTimer()
            {
                var input = new RecordableTime
                {
                    EntryNo = Fixture.Integer(),
                    CaseKey = Fixture.Integer(),
                    NameKey = Fixture.Integer(),
                    Start = Fixture.Today().AddHours(8),
                    TotalTime = Fixture.BaseDate().AddMinutes(10)
                };
                var f = new TimerControllerFixture(Db);
                f.TimerUpdate.UpdateTimer(Arg.Any<RecordableTime>(), Arg.Any<bool>(), Arg.Any<bool>()).Returns(Task.FromResult(new DiaryKeyDetails(f.CurrentStaffId, input.EntryNo.Value)));

                var stoppedEntry = Substitute.ForPartsOf<TimeEntry>();
                stoppedEntry.EntryNo = input.EntryNo;
                stoppedEntry.StaffId = f.CurrentStaffId;
                stoppedEntry.StartTime = new DateTime();
                stoppedEntry.IsTimer = true;
                f.TimesheetList.Get(Arg.Any<int>(), Arg.Any<IQueryable<Diary>>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<TimeEntry> {stoppedEntry});

                var result = await f.Subject.Save(new SaveTimerData {TimeEntry = input, StopTimer = false});
                await f.WipWarningCheck.Received(1).For(input.CaseKey, input.NameKey);
                await f.TimerUpdate.Received(1).UpdateTimer(input, false, true);
                Assert.Equal(input.EntryNo, result.Response.EntryNo);
                f.Bus.Received(1).Publish(Arg.Is<BroadcastMessageToClient>(x => x.Topic.StartsWith("time.recording.timerStarted") && ((TimerStateInfo) x.Data).BasicDetails.MakeUiReady() == stoppedEntry));
                stoppedEntry.Received(1).MakeUiReady();
            }

            [Fact]
            public async Task CallsToSaveEntryWithStopTimer()
            {
                var input = new RecordableTime
                {
                    EntryNo = Fixture.Integer(),
                    CaseKey = Fixture.Integer(),
                    NameKey = Fixture.Integer(),
                    Start = Fixture.Today().AddHours(8),
                    TotalTime = Fixture.BaseDate().AddMinutes(10)
                };
                var f = new TimerControllerFixture(Db);

                var stoppedEntry = Substitute.ForPartsOf<TimeEntry>();
                stoppedEntry.EntryNo = input.EntryNo;
                stoppedEntry.StaffId = f.CurrentStaffId;
                stoppedEntry.StartTime = new DateTime();
                stoppedEntry.IsTimer = false;

                f.TimesheetList.Get(Arg.Any<int>(), Arg.Any<IQueryable<Diary>>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<TimeEntry> {stoppedEntry});

                f.TimerUpdate.UpdateTimer(Arg.Any<RecordableTime>(), Arg.Any<bool>(), Arg.Any<bool>()).Returns(Task.FromResult(new DiaryKeyDetails(f.CurrentStaffId, input.EntryNo.Value)));
                var result = await f.Subject.Save(new SaveTimerData {TimeEntry = input, StopTimer = true});
                await f.WipWarningCheck.Received(1).For(input.CaseKey, input.NameKey);
                await f.TimerUpdate.Received(1).UpdateTimer(input, true, true);
                Assert.Equal(input.EntryNo, result.Response.EntryNo);
                f.Bus.Received(1).Publish(Arg.Is<BroadcastMessageToClient>(x => x.Topic.StartsWith("time.recording.timerStarted") && ((TimerStateInfo) x.Data).BasicDetails.MakeUiReady() == stoppedEntry));
                stoppedEntry.Received(1).MakeUiReady();
            }
        }

        public class ResetTimer : FactBase
        {
            [Fact]
            public async Task ReturnsExceptionWhenNoTimeEntrySpecified()
            {
                var f = new TimerControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Reset(null));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.DidNotReceive().For(Arg.Any<int>(), Arg.Any<int>());
                await f.TimerUpdate.DidNotReceive().UpdateTimer(Arg.Any<RecordableTime>());
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ReturnsExceptionWhenNoEntryNoSpecified()
            {
                var input = new RecordableTime();
                var f = new TimerControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Reset(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.DidNotReceive().For(Arg.Any<int>(), Arg.Any<int>());
                await f.TimerUpdate.DidNotReceive().UpdateTimer(Arg.Any<RecordableTime>());
                Db.DidNotReceive().Set<Diary>();
                await Db.DidNotReceive().SaveChangesAsync();
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ChecksWipWarningsBeforeSave()
            {
                var input = new RecordableTime
                {
                    EntryNo = Fixture.Integer(),
                    CaseKey = Fixture.Integer(),
                    NameKey = Fixture.Integer()
                };
                var f = new TimerControllerFixture(Db);
                f.WipWarningCheck.For(input.CaseKey, input.NameKey).Throws(new HttpResponseException(HttpStatusCode.BadRequest));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Reset(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.WipWarningCheck.Received(1).For(input.CaseKey, input.NameKey);
                await f.TimerUpdate.DidNotReceive().UpdateTimer(Arg.Any<RecordableTime>());
                Db.DidNotReceive().Set<Diary>();
                await Db.DidNotReceive().SaveChangesAsync();
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ChecksFunctionSecurity()
            {
                var input = new RecordableTime
                {
                    EntryNo = Fixture.Integer(),
                    CaseKey = Fixture.Integer(),
                    NameKey = Fixture.Integer(),
                    StaffId = Fixture.Integer()
                };
                var f = new TimerControllerFixture(Db);
                f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int?>()).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Reset(input));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                Db.DidNotReceive().Set<Diary>();
                await Db.DidNotReceive().SaveChangesAsync();
                f.Bus.DidNotReceiveWithAnyArgs().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task PublishesInfoAfterSavesUpdates()
            {
                var f = new TimerControllerFixture(Db);
                var stoppedEntry = Substitute.ForPartsOf<TimeEntry>();
                stoppedEntry.EntryNo = 11;
                stoppedEntry.StaffId = f.CurrentStaffId;
                stoppedEntry.StartTime = new DateTime();
                stoppedEntry.IsTimer = false;
                f.TimesheetList.Get(Arg.Any<int>(), Arg.Any<IQueryable<Diary>>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<TimeEntry> {stoppedEntry});
                f.TimerUpdate.ResetTimer(Arg.Any<RecordableTime>()).ReturnsForAnyArgs(Task.FromResult(new DiaryKeyDetails(f.CurrentStaffId, 11)));

                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    TotalTime = Fixture.BaseDate().AddMinutes(30),
                    CaseKey = Fixture.Integer(),
                    NameKey = Fixture.Integer(),
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today(),
                    EntryNo = 11
                };

                var result = await f.Subject.Reset(input);
                var updatedTimer = (TimeEntry) result.Response.TimeEntry;

                Assert.Equal(stoppedEntry, updatedTimer);
                f.TimerUpdate.Received(1).ResetTimer(Arg.Is<RecordableTime>(p => p == input)).IgnoreAwaitForNSubstituteAssertion();
                f.Bus.Received(1).Publish(Arg.Is<BroadcastMessageToClient>(x => x.Topic.StartsWith("time.recording.timerStarted") && ((TimerStateInfo) x.Data).BasicDetails.MakeUiReady() == stoppedEntry));
            }
        }

        public class CheckCurrentlyRunningTimer : FactBase
        {
            [Fact]
            public async Task StopsPreviousTimer()
            {
                var f = new TimerControllerFixture(Db);
                await f.Subject.CheckCurrentlyRunningTimer();
                await f.TimerUpdate.Received(1).StopPrevTimer(f.CurrentStaffId);
            }

            [Theory]
            [InlineData(true, false)]
            [InlineData(false, false)]
            public async Task ReturnsCurrentlyRunningTimer(bool is12HourFormat, bool displaySeconds)
            {
                var f = new TimerControllerFixture(Db);
                f.UserPreference.GetPreference<bool>(Arg.Any<int>(), KnownSettingIds.TimeFormat12Hours).Returns(is12HourFormat);
                f.UserPreference.GetPreference<bool>(Arg.Any<int>(), KnownSettingIds.DisplayTimeWithSeconds).Returns(displaySeconds);

                var result = await f.Subject.CheckCurrentlyRunningTimer();

                f.TimesheetList.Received(1).GetRunningTimersFor(f.CurrentStaffId, Fixture.Today());
                Assert.Equal(is12HourFormat, result.TimeFormat12Hours);
                Assert.Equal(displaySeconds, result.DisplaySeconds);
            }
        }

        public class ContinueAsTimer : FactBase
        {
            [Fact]
            public async Task ChecksFunctionSecurity()
            {
                var f = new TimerControllerFixture(Db);
                f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int?>()).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.ContinueTimer(new TimerSeed() {ContinueFromEntryNo = 1}));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
                Db.DidNotReceive().Set<Diary>();
                await Db.DidNotReceive().SaveChangesAsync();
                f.Bus.DidNotReceive().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task ReturnsExceptionForInvalidEntry()
            {
                var f = new TimerControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.ContinueTimer(new TimerSeed {ContinueFromEntryNo = null}));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await f.TimerUpdate.DidNotReceive().StopTimerFor(Arg.Any<int>(), Arg.Any<DateTime>());
                await Db.DidNotReceive().SaveChangesAsync();
                f.Bus.DidNotReceive().Publish(Arg.Any<BroadcastMessageToClient>());
            }

            [Fact]
            public async Task UpdatesDataAndReturnsContinuedEntry()
            {
                var f = new TimerControllerFixture(Db);

                var startedEntry = Substitute.ForPartsOf<TimeEntry>();
                startedEntry.EntryNo = 99;
                startedEntry.StaffId = f.CurrentStaffId;
                startedEntry.StartTime = Fixture.TodayTime();
                startedEntry.IsTimer = true;
                var stoppedEntry = Substitute.ForPartsOf<TimeEntry>();
                stoppedEntry.EntryNo = 1;
                stoppedEntry.StaffId = f.CurrentStaffId;
                stoppedEntry.IsTimer = false;
                f.TimesheetList.Get(Arg.Any<int>(), Arg.Any<IQueryable<Diary>>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<TimeEntry> {startedEntry, stoppedEntry});
                f.TimerUpdate.StopTimerFor(Arg.Any<int>(), Arg.Any<DateTime>()).Returns(new DiaryKeyDetails(f.CurrentStaffId, stoppedEntry.EntryNo.Value));
                f.TimerUpdate.ContinueTimer(Arg.Any<TimerSeed>()).Returns(new DiaryKeyDetails(f.CurrentStaffId, startedEntry.EntryNo.Value));

                var seed = new TimerSeed {StaffNameId = f.CurrentStaffId, ContinueFromEntryNo = 3, StartDateTime = startedEntry.StartTime.Value};
                var result = await f.Subject.ContinueTimer(seed);
                f.TimerUpdate.Received(1).StopTimerFor(f.CurrentStaffId, startedEntry.StartTime.Value).IgnoreAwaitForNSubstituteAssertion();
                f.TimerUpdate.Received(1).ContinueTimer(Arg.Is<TimerSeed>(_ => _ == seed)).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(startedEntry, result.StartedTimer);
                Assert.Equal(stoppedEntry, result.StoppedTimer);
                startedEntry.Received(1).MakeUiReady();
                stoppedEntry.Received(1).MakeUiReady();
                f.Bus.Received(1).Publish(Arg.Is<BroadcastMessageToClient>(x => x.Topic.StartsWith("time.recording.timerStarted") && ((TimerStateInfo) x.Data).BasicDetails.MakeUiReady() == startedEntry));
            }
        }

        class TimerControllerFixture : IFixture<TimerController>
        {
            public TimerControllerFixture(InMemoryDbContext db)
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                CurrentUser = new UserBuilder(db).Build();
                SecurityContext.User.Returns(CurrentUser);

                FunctionSecurityProvider = Substitute.For<IFunctionSecurityProvider>();
                FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int?>()).Returns(true);

                Now = Substitute.For<Func<DateTime>>();
                Now().Returns(Fixture.Today());

                TimerUpdate = Substitute.For<ITimerUpdate>();

                WipWarningCheck = Substitute.For<IWipWarningCheck>();
                WipWarningCheck.For(Arg.Any<int>(), Arg.Any<int>()).Returns(Task.FromResult(true));
                TimesheetList = Substitute.For<ITimesheetList>();
                Bus = Substitute.For<IBus>();
                UserPreference = Substitute.For<IUserPreferenceManager>();

                Subject = new TimerController(SecurityContext, FunctionSecurityProvider, Now, WipWarningCheck, TimerUpdate, Bus, TimesheetList, UserPreference);
            }

            public IUserPreferenceManager UserPreference { get; }
            public IBus Bus { get; }
            ISecurityContext SecurityContext { get; }
            public User CurrentUser { get; }
            public int CurrentStaffId => CurrentUser.NameId;
            public IFunctionSecurityProvider FunctionSecurityProvider { get; }
            Func<DateTime> Now { get; }
            public ITimerUpdate TimerUpdate { get; }
            public IWipWarningCheck WipWarningCheck { get; }
            public ITimesheetList TimesheetList { get; }
            public TimerController Subject { get; }
        }
    }
}