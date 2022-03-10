using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;

namespace Inprotech.Web.Accounting.Time.Timers
{
    public interface ITimerUpdate
    {
        Task<DiaryKeyDetails> StartTimerFor(int staffId, TimerSeed seed);
        Task<DiaryKeyDetails> StopTimerFor(int staffId, DateTime stopTime);
        Task<DiaryKeyDetails> StopPrevTimer(int staffId);
        Task<DiaryKeyDetails> UpdateTimer(RecordableTime timer, bool stopTimer = false, bool updateData = false);
        Task<DiaryKeyDetails> ResetTimer(RecordableTime timer);
        Task<DiaryKeyDetails> ContinueTimer(TimerSeed init);
    }

    public class TimerUpdate : ITimerUpdate
    {
        readonly ITimesheetList _timesheetList;
        readonly IWipDefaulting _wipDefaulter;
        readonly IDiaryTimerUpdater _diaryTimerUpdater;
        readonly IDiaryUpdate _diaryUpdator;

        public TimerUpdate(ITimesheetList timesheetList,
                           IWipDefaulting wipDefaulter,
                           IDiaryTimerUpdater diaryTimerUpdater,
                           IDiaryUpdate diaryUpdator)
        {
            _timesheetList = timesheetList;
            _wipDefaulter = wipDefaulter;
            _diaryTimerUpdater = diaryTimerUpdater;
            _diaryUpdator = diaryUpdator;
        }

        public async Task<DiaryKeyDetails> StartTimerFor(int staffId, TimerSeed seed)
        {
            if (seed == null) throw new ArgumentNullException(nameof(seed));
            if (!seed.StartDateTime.HasValue) throw new ArgumentNullException(nameof(seed.StartDateTime));

            var wipTemplateFilter = new WipTemplateFilterCriteria().ForTimesheet(seed.CaseKey);
            var wipDefaults = seed.CaseKey.HasValue ? await _wipDefaulter.ForCase(wipTemplateFilter, seed.CaseKey.Value) : null;

            var recordableTime = new RecordableTime
            {
                StaffId = staffId,
                Start = seed.StartDateTime,
                CaseKey = seed.CaseKey,
                Activity = wipDefaults?.WIPTemplateKey,
                NarrativeNo = (short?) wipDefaults?.NarrativeKey,
                NarrativeText = wipDefaults?.NarrativeText,
                Finish = null,
                EntryDate = seed.StartDateTime.Value.Date,
                isTimer = true
            };

            var newDiary = await _diaryUpdator.AddEntry(recordableTime);

            return newDiary.EntryNo != null ? new DiaryKeyDetails(newDiary.StaffId, newDiary.EntryNo.Value) : null;
        }

        public async Task<DiaryKeyDetails> StopTimerFor(int staffId, DateTime stopTime)
        {
            var timerQuery = _timesheetList.GetRunningTimersFor(staffId, stopTime.Date).OrderByDescending(_ => _.StartTime).Take(1);
            return await _diaryTimerUpdater.StopTimerEntry(timerQuery, stopTime);
        }

        public async Task<DiaryKeyDetails> StopPrevTimer(int staffId)
        {
            var timerQuery = _timesheetList.GetRunningTimersFor(staffId).OrderByDescending(_ => _.StartTime).Take(1);
            return await _diaryTimerUpdater.UpdateTimeForTimerEntry(timerQuery);
        }

        public async Task<DiaryKeyDetails> UpdateTimer(RecordableTime timer, bool stopTimer = false, bool updateData = false)
        {
            if (!timer.StaffId.HasValue) throw new ArgumentNullException(nameof(timer.StaffId));
            if (!timer.EntryNo.HasValue) throw new ArgumentNullException(nameof(timer.EntryNo));

            timer.isTimer = true;

            if (updateData && stopTimer)
                return await _diaryTimerUpdater.UpdateTimeAndDataForTimerEntry(timer, timer.TotalTime);

            if (updateData)
                await _diaryUpdator.UpdateEntry(timer);

            if (stopTimer)
                await _diaryTimerUpdater.UpdateTimeForTimerEntry(_timesheetList.GetRunningTimersFor(timer.StaffId.Value, entryNo: timer.EntryNo).Take(1), timer.TotalTime);

            return new DiaryKeyDetails(timer.StaffId.Value, timer.EntryNo.Value);
        }

        public async Task<DiaryKeyDetails> ResetTimer(RecordableTime timer)
        {
            if (!timer.StaffId.HasValue) throw new ArgumentNullException(nameof(timer.StaffId));
            if (!timer.EntryNo.HasValue) throw new ArgumentNullException(nameof(timer.EntryNo));
            if (!timer.Start.HasValue) throw new ArgumentNullException(nameof(timer.Start));

            return await _diaryTimerUpdater.ResetTimeForTimerEntry(_timesheetList.GetRunningTimersFor(timer.StaffId.Value, entryNo: timer.EntryNo), timer.Start.Value);
        }

        public async Task<DiaryKeyDetails> ContinueTimer(TimerSeed init)
        {
            if (!init.StaffNameId.HasValue) throw new ArgumentNullException(nameof(init.StaffNameId));
            if (!init.ContinueFromEntryNo.HasValue) throw new ArgumentNullException(nameof(init.ContinueFromEntryNo));
            if (!init.StartDateTime.HasValue) throw new ArgumentNullException(nameof(init.StartDateTime));

            return await _diaryTimerUpdater.AddContinuedTimerEntry(init.StaffNameId.Value, init.ContinueFromEntryNo.Value, init.StartDateTime.Value);
        }
    }
}