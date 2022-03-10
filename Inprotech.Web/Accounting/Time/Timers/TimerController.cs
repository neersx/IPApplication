using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Messages;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Accounting.Time.Timers
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)]
    [RoutePrefix("api/accounting/timer")]
    public class TimerController : ApiController
    {
        readonly IFunctionSecurityProvider _functionSecurity;
        readonly Func<DateTime> _now;
        readonly ISecurityContext _securityContext;
        readonly IWipWarningCheck _wipWarningCheck;
        readonly ITimerUpdate _timerUpdate;
        readonly IBus _bus;
        readonly ITimesheetList _timesheetList;
        readonly IUserPreferenceManager _preferenceManager;
        const string TimerTopic = "time.recording.timerStarted";

        public TimerController(ISecurityContext securityContext,
                               IFunctionSecurityProvider functionSecurity,
                               Func<DateTime> now,
                               IWipWarningCheck wipWarningCheck,
                               ITimerUpdate timerUpdate,
                               IBus bus,
                               ITimesheetList timesheetList,
                               IUserPreferenceManager preferenceManager)
        {
            _securityContext = securityContext;
            _functionSecurity = functionSecurity;
            _now = now;
            _wipWarningCheck = wipWarningCheck;
            _timerUpdate = timerUpdate;
            _bus = bus;
            _timesheetList = timesheetList;
            _preferenceManager = preferenceManager;
        }

        [HttpPost]
        [RequiresCaseAuthorization(PropertyPath = "init.CaseKey")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        [Route("start")]
        public async Task<TimerEntries> StartTimer(TimerSeed init)
        {
            init.StaffNameId = init.StaffNameId ?? _securityContext.User.NameId;
            await CheckSecurity(init.StaffNameId.Value);

            var stoppedTimerKeyDetails = await _timerUpdate.StopTimerFor(init.StaffNameId.Value, init.StartDateTime ?? _now());
            var startedTimerKeyDetails = await _timerUpdate.StartTimerFor(init.StaffNameId.Value, init);

            var (startedTimer, stoppedTimer) = await GetTimeEntriesFor(init.StaffNameId.Value, startedTimerKeyDetails?.EntryNo, stoppedTimerKeyDetails?.EntryNo);

            PublishDetails(startedTimer);
            return new TimerEntries {StartedTimer = startedTimer, StoppedTimer = stoppedTimer};
        }

        [HttpPut]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        [Route("stop")]
        public async Task<dynamic> Stop(RecordableTime timeEntry)
        {
            if (timeEntry?.EntryNo == null) throw new HttpResponseException(HttpStatusCode.BadRequest);
            timeEntry.StaffId ??= _securityContext.User.NameId;

            await CheckSecurity(timeEntry.StaffId.Value);

            return await SaveOrStop(timeEntry, true);
        }

        [HttpPut]
        [RequiresCaseAuthorization(PropertyPath = "data.TimeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "data.TimeEntry.NameKey")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        [Route("save")]
        public async Task<dynamic> Save(SaveTimerData data)
        {
            if (data?.TimeEntry?.EntryNo == null) throw new HttpResponseException(HttpStatusCode.BadRequest);
            data.TimeEntry.StaffId ??= _securityContext.User.NameId;

            await CheckSecurity(data.TimeEntry.StaffId.Value);

            return await SaveOrStop(data.TimeEntry, data.StopTimer, true);
        }

        async Task<dynamic> SaveOrStop(RecordableTime inputEntry, bool stopTimer = false, bool updateData = false)
        {
            if (!await _wipWarningCheck.For(inputEntry.CaseKey, inputEntry.NameKey))
                return null;

            var updatedEntryKeyDetails = await _timerUpdate.UpdateTimer(inputEntry, stopTimer, updateData);

            var updatedEntry = (await GetTimeEntriesFor(updatedEntryKeyDetails.EmployeeNo, updatedEntryKeyDetails.EntryNo)).startedTimer;
            PublishDetails(updatedEntry);
            return new
            {
                Response = new {updatedEntryKeyDetails.EntryNo, TimeEntry = updatedEntry}
            };
        }

        [HttpPut]
        [RequiresCaseAuthorization(PropertyPath = "timeEntry.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "timeEntry.NameKey")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        [Route("reset")]
        public async Task<dynamic> Reset(RecordableTime timeEntry)
        {
            if (timeEntry?.EntryNo == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            timeEntry.StaffId = timeEntry.StaffId ?? _securityContext.User.NameId;
            await CheckSecurity(timeEntry.StaffId.Value);

            if (!await _wipWarningCheck.For(timeEntry.CaseKey, timeEntry.NameKey))
                return null;

            var timerKeyDetails = await _timerUpdate.ResetTimer(timeEntry);
            if (timerKeyDetails == null)
                return null;

            var (startedTimer, _) = await GetTimeEntriesFor(timerKeyDetails.EmployeeNo, timerKeyDetails.EntryNo);

            PublishDetails(startedTimer);
            return new
            {
                Response = new {startedTimer.EntryNo, TimeEntry = startedTimer}
            };
        }

        [HttpGet]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        [Route("currentRunningTimer")]
        public async Task<dynamic> CheckCurrentlyRunningTimer()
        {
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, _securityContext.User, _securityContext.User.NameId))
                return null;

            var staffId = _securityContext.User.NameId;
            var today = _now().Date;

            var stoppedTimer = await _timerUpdate.StopPrevTimer(staffId);
            var runningTimerQuery = _timesheetList.GetRunningTimersFor(staffId, today).OrderByDescending(_ => _.StartTime).Take(1);

            TimeEntry stoppedEntry = null;
            TimeEntry runningEntry;
            if (stoppedTimer == null)
            {
                runningEntry = (await _timesheetList.Get(staffId, runningTimerQuery)).SingleOrDefault()?.MakeUiReady();
            }
            else
            {
                var timerDetails = (await _timesheetList.Get(staffId, runningTimerQuery, stoppedTimer.EntryNo)).ToArray();
                stoppedEntry = timerDetails.SingleOrDefault(_ => _.EntryNo == stoppedTimer.EntryNo)?.MakeUiReady();
                runningEntry = timerDetails.SingleOrDefault(_ => _.EntryNo != stoppedTimer.EntryNo)?.MakeUiReady();
            }

            return new
            {
                TimeFormat12Hours = _preferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.TimeFormat12Hours),
                DisplaySeconds = _preferenceManager.GetPreference<bool>(_securityContext.User.Id, KnownSettingIds.DisplayTimeWithSeconds),
                StoppedTimer = stoppedEntry,
                RunningTimer = runningEntry
            };
        }

        [HttpPost]
        [RequiresCaseAuthorization(PropertyPath = "init.CaseKey")]
        [AppliesToComponent(KnownComponents.TimeRecording)]
        [Route("continue")]
        public async Task<TimerEntries> ContinueTimer(TimerSeed init)
        {
            if (init?.ContinueFromEntryNo == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            init.StaffNameId = init.StaffNameId ?? _securityContext.User.NameId;
            await CheckSecurity(init.StaffNameId.Value);

            var stoppedTimer = await _timerUpdate.StopTimerFor(init.StaffNameId.Value, init.StartDateTime ?? _now());
            var newContinuedTimerKeyDetails = await _timerUpdate.ContinueTimer(init);

            var (startedTimer, timeEntry) = await GetTimeEntriesFor(init.StaffNameId.Value, newContinuedTimerKeyDetails?.EntryNo, stoppedTimer?.EntryNo);

            PublishDetails(startedTimer);
            return new TimerEntries
            {
                StartedTimer = startedTimer, StoppedTimer = timeEntry
            };
        }

        async Task CheckSecurity(int staffNameId)
        {
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanUpdate, _securityContext.User, staffNameId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);
        }

        async Task<(TimeEntry startedTimer, TimeEntry stoppedTimer)> GetTimeEntriesFor(int staffId, int? startedTimerEntryNo = null, int? stoppedTimerEntryNo = null)
        {
            var entryNos = new[] {startedTimerEntryNo, stoppedTimerEntryNo}
                           .Where(_ => _.HasValue)
                           .Select(_ => _.Value)
                           .ToArray();

            var entryDetails = (await _timesheetList.Get(staffId, entryNos: entryNos)).ToArray();

            var startedTimer = entryDetails.SingleOrDefault(_ => _.EntryNo == startedTimerEntryNo);
            var stoppedTimer = entryDetails.SingleOrDefault(_ => _.EntryNo == stoppedTimerEntryNo);

            return (startedTimer.MakeUiReady(), stoppedTimer.MakeUiReady());
        }

        BroadcastMessageToClient GetMessage(TimerStateInfo info)
        {
            return new BroadcastMessageToClient
            {
                Topic = TimerTopic + _securityContext.User.Id,
                Data = info
            };
        }

        void PublishDetails(TimeEntry entry)
        {
            if (entry == null || entry.StaffId != _securityContext.User.NameId)
                return;

            var data = entry.IsTimer ? TimerStateInfo.StartedTimer(entry) : TimerStateInfo.StoppedTimer(entry);
            _bus.Publish(GetMessage(data));
        }
    }

    public class TimerSeed
    {
        public DateTime? StartDateTime { get; set; }
        public int? StaffNameId { get; set; }
        public int? ContinueFromEntryNo { get; set; }
        public int? CaseKey { get; set; }
    }

    public class TimerEntries
    {
        public TimeEntry StartedTimer { get; set; }
        public TimeEntry StoppedTimer { get; set; }
    }
}