using System;
using System.Data.Entity;
using System.IdentityModel.Protocols.WSTrust;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public interface IDiaryTimerUpdater
    {
        Task<DiaryKeyDetails> AddContinuedTimerEntry(int staffId, int continuedFromEntryNo, DateTime startTime);
        Task<DiaryKeyDetails> UpdateTimeAndDataForTimerEntry(RecordableTime timer, DateTime? totalTime = null);
        Task<DiaryKeyDetails> UpdateTimeForTimerEntry(IQueryable<Diary> selectableEntry, DateTime? totalTime = null);
        Task<DiaryKeyDetails> ResetTimeForTimerEntry(IQueryable<Diary> selectableEntry, DateTime newStartTime);
        Task<DiaryKeyDetails> StopTimerEntry(IQueryable<Diary> selectableEntry, DateTime stopTime);
    }

    public class DiaryTimerUpdater : IDiaryTimerUpdater
    {
        readonly IDbContext _dbContext;
        readonly IMapper _mapper;
        readonly IValueTime _valueTime;
        readonly Func<DateTime> _now;
        readonly IChainUpdater _chainUpdater;
        readonly IDebtorSplitUpdater _splitUpdater;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public DiaryTimerUpdater(IDbContext dbContext, IMapper mapper, IValueTime valueTime, Func<DateTime> now, IChainUpdater chainUpdater, IDebtorSplitUpdater splitUpdater, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _valueTime = valueTime;
            _now = now;
            _chainUpdater = chainUpdater;
            _splitUpdater = splitUpdater;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public async Task<DiaryKeyDetails> AddContinuedTimerEntry(int staffId, int continuedFromEntryNo, DateTime startTime)
        {
            var diaryTable = _dbContext.Set<Diary>();
            
            var list = (await _chainUpdater.GetDownwardChain(staffId, startTime.Date, continuedFromEntryNo)).ToList();
            var firstEntry = list.First();
            var newInput = _mapper.Map<RecordableTime>(firstEntry);
            newInput.Finish = null;
            newInput.ParentEntryNo = continuedFromEntryNo;
            newInput.Start = startTime;
            newInput.isTimer = true;
            newInput.TotalUnits = null;
            newInput.TotalTime = null;
            var newDiary =_mapper.Map<Diary>(newInput);

            newDiary.CreatedOn = _now();
            newDiary.EntryNo = diaryTable.GetNewEntryNoFor(staffId);
            newDiary.TimeCarriedForward = new DateTime(1899, 1, 1).AddTicks(firstEntry.TimeCarriedForward.GetValueOrDefault().TimeOfDay.Ticks + firstEntry.TotalTime.GetValueOrDefault().TimeOfDay.Ticks);
            newDiary.TimerStarted = _now();

            diaryTable.Add(newDiary);

            firstEntry.ClearParentValues();
            _splitUpdater.PurgeSplits(firstEntry);

            await _dbContext.SaveChangesAsync();
            return new DiaryKeyDetails(staffId, newDiary.EntryNo);
        }

        public async Task<DiaryKeyDetails> UpdateTimeAndDataForTimerEntry(RecordableTime timer, DateTime? totalTime = null)
        {
            if (timer == null) throw new ArgumentNullException(nameof(timer));
            if (!timer.StaffId.HasValue) throw new ArgumentNullException(nameof(timer.StaffId));
            if (!timer.EntryNo.HasValue) throw new ArgumentNullException(nameof(timer.EntryNo));

            var list = (await _chainUpdater.GetDownwardChain(timer.StaffId.Value, timer.Start ?? timer.EntryDate, timer.EntryNo.Value)).ToList();

            var firstEntry = list.First();
            if (firstEntry.IsTimer != 1)
                throw new InvalidRequestException("This timer is no more running");

            timer = timer.AdjustDataForWipCalculation(timer.ParentEntryNo.HasValue ? firstEntry.TimeCarriedForward : null);
            timer.isTimer = false;
            _mapper.Map(timer, firstEntry);
            
            if (!firstEntry.TrySetFinishTimeForTimer(totalTime))
                return null;

            if (firstEntry.TotalTime.GetValueOrDefault().TimeOfDay.TotalSeconds > 0)
            {
                var costedEntry = await _valueTime.For(timer, _preferredCultureResolver.Resolve());
                _mapper.Map(costedEntry, firstEntry);
                _splitUpdater.UpdateSplits(firstEntry, costedEntry?.DebtorSplits);
            }
            _chainUpdater.UpdateData(list, firstEntry, true, true);
            firstEntry.TimerStarted = null;

            await _dbContext.SaveChangesAsync();

            return new DiaryKeyDetails(timer.StaffId.Value, timer.EntryNo.Value);
        }

        public async Task<DiaryKeyDetails> UpdateTimeForTimerEntry(IQueryable<Diary> selectableEntry, DateTime? totalTime = null)
        {
            var diaryEntry = await selectableEntry.SingleOrDefaultAsync();
            if (diaryEntry == null || !diaryEntry.TrySetFinishTimeForTimer(totalTime))
                return null;

            var entry = _mapper.Map<RecordableTime>(diaryEntry);

            var costedEntry = await _valueTime.For(entry, _preferredCultureResolver.Resolve());
            _mapper.Map(costedEntry, diaryEntry);
            _splitUpdater.UpdateSplits(diaryEntry, costedEntry?.DebtorSplits);
            diaryEntry.IsTimer = 0;
            diaryEntry.TimerStarted = null;

            await _dbContext.SaveChangesAsync();
            return new DiaryKeyDetails(diaryEntry.EmployeeNo, diaryEntry.EntryNo);
        }

        public async Task<DiaryKeyDetails> StopTimerEntry(IQueryable<Diary> selectableEntry, DateTime stopTime)
        {
            var diaryEntry = await selectableEntry.SingleOrDefaultAsync();
            if (diaryEntry == null || !diaryEntry.TryStopTimer(stopTime))
                return null;

            var entry = _mapper.Map<RecordableTime>(diaryEntry);

            var costedEntry = await _valueTime.For(entry, _preferredCultureResolver.Resolve());
            _mapper.Map(costedEntry, diaryEntry);
            _splitUpdater.UpdateSplits(diaryEntry, costedEntry?.DebtorSplits);
            diaryEntry.IsTimer = 0;
            diaryEntry.TimerStarted = null;

            await _dbContext.SaveChangesAsync();
            return new DiaryKeyDetails(diaryEntry.EmployeeNo, diaryEntry.EntryNo);
        }

        public async Task<DiaryKeyDetails> ResetTimeForTimerEntry(IQueryable<Diary> selectableEntry, DateTime newStartTime)
        {
            var diaryEntry = await selectableEntry.SingleOrDefaultAsync();
            if (diaryEntry == null)
                return null;

            _splitUpdater.PurgeSplits(diaryEntry);
            diaryEntry.StartTime = newStartTime;
            diaryEntry.TimerStarted = _now();

            await _dbContext.SaveChangesAsync();
            return new DiaryKeyDetails(diaryEntry.EmployeeNo, diaryEntry.EntryNo);
        }
    }
}