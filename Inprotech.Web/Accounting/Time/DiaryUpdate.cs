using System;
using System.Collections.Generic;
using System.IdentityModel.Protocols.WSTrust;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using AutoMapper;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Persistence;
using Z.EntityFramework.Plus;

namespace Inprotech.Web.Accounting.Time
{
    public interface IDiaryUpdate
    {
        Task<TimeEntry> AddEntry(RecordableTime entry);
        Task<int> AddEntries(Diary entry, IOrderedEnumerable<DateTime> copyToDates);
        Task<TimeEntry> UpdateEntry(RecordableTime inputEntry, int? transNo = null);
        Task<bool> UpdateDate(RecordableTime input);
        Task<Diary> DeleteEntry(RecordableTime entry);
        Task<bool> DeleteChainFor(RecordableTime entry);
        Task<(Diary diaryToRemove, Diary newLastChild)> RemoveEntryFromChain(IEnumerable<Diary> chain, RecordableTime timeEntry);
        Task<int> BatchDelete(int forStaffNameId, IEnumerable<int> entryNos);
        Task<int> BatchUpdateNarratives(int forStaffNameId, IEnumerable<int> entryNos, string narrativeText, short? narrativeNo = null);
    }

    public class DiaryUpdate : IDiaryUpdate
    {
        readonly IDbContext _dbContext;
        readonly IMapper _mapper;
        readonly IValueTime _valueTime;
        readonly Func<DateTime> _now;
        readonly IChainUpdater _chainUpdater;
        readonly IWipWarningCheck _wipWarningCheck;
        readonly IDebtorSplitUpdater _splitUpdater;
        readonly IPreferredCultureResolver _cultureResolver;

        public DiaryUpdate(IDbContext dbContext, IMapper mapper, IValueTime valueTime, Func<DateTime> now, IChainUpdater chainUpdater, IWipWarningCheck wipWarningCheck, IDebtorSplitUpdater splitUpdater, IPreferredCultureResolver cultureResolver)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _valueTime = valueTime;
            _now = now;
            _chainUpdater = chainUpdater;
            _wipWarningCheck = wipWarningCheck;
            _splitUpdater = splitUpdater;
            _cultureResolver = cultureResolver;
        }

        public async Task<TimeEntry> AddEntry(RecordableTime inputEntry)
        {
            if (inputEntry.StaffId == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var diaryTable = _dbContext.Set<Diary>();

            var newDiary = new Diary {CreatedOn = _now()};
            inputEntry.EntryNo = newDiary.EntryNo = diaryTable.GetNewEntryNoFor(inputEntry.StaffId.Value);
            inputEntry = inputEntry.AdjustDataForWipCalculation();
            _mapper.Map(inputEntry, newDiary);
            newDiary.TimeCarriedForward = inputEntry.ParentEntryNo != null ? inputEntry.TimeCarriedForward.GetValueOrDefault().TimeOfDay != TimeSpan.Zero ? inputEntry.TimeCarriedForward : inputEntry.TotalTime : null;
            newDiary.TimerStarted = inputEntry.isTimer ? _now() : null;

            if (inputEntry.IsCostableEntry)
            {
                var costedEntry = await _valueTime.For(inputEntry, _cultureResolver.Resolve());
                _mapper.Map(costedEntry, newDiary);
                _splitUpdater.UpdateSplits(newDiary, costedEntry?.DebtorSplits);
            }

            diaryTable.Add(newDiary);

            if (inputEntry.ParentEntryNo.HasValue)
            {
                var list = (await _chainUpdater.GetDownwardChain(inputEntry.StaffId.Value, inputEntry.EntryDate.Date, inputEntry.ParentEntryNo.Value)).ToList();
                var firstEntry = list.First();
                if (firstEntry.TransactionId != null || firstEntry.WipEntityId != null)
                    throw new InvalidRequestException("Can not add continuation to already posted entry");

                firstEntry.ClearParentValues();
                _splitUpdater.PurgeSplits(firstEntry);

                _chainUpdater.UpdateData(list, newDiary);
            }

            await _dbContext.SaveChangesAsync();
            return _mapper.Map<TimeEntry>(newDiary);
        }

        public async Task<int> AddEntries(Diary entry, IOrderedEnumerable<DateTime> copyToDates)
        {
            var newEntries = new List<Diary>();
            foreach (var copyTo in copyToDates)
            {
                var newEntry = _mapper.Map<RecordableTime>(entry);
                newEntry.Start = copyTo.Date.Add(entry.StartTime.GetValueOrDefault().TimeOfDay);
                newEntry.Finish = copyTo.Date.Add(entry.FinishTime.GetValueOrDefault().TimeOfDay);
                newEntry.TotalTime = entry.TotalTime;

                var costedTime = await _valueTime.For(newEntry.AdjustDataForWipCalculation(), _cultureResolver.Resolve());

                var newDiary = new Diary();
                _mapper.Map(newEntry, newDiary);
                _mapper.Map(costedTime, newDiary);
                _splitUpdater.UpdateSplits(newDiary, costedTime.DebtorSplits);

                newEntries.Add(newDiary);
            }

            using (var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled))
            {
                var diaryTable = _dbContext.Set<Diary>();
                var entryNo = diaryTable.GetNewEntryNoFor(entry.EmployeeNo);
                newEntries.ForEach(e =>
                {
                    e.EntryNo = entryNo++;
                    e.CreatedOn = _now();
                    diaryTable.Add(e);
                });
                await _dbContext.SaveChangesAsync();
                tsc.Complete();
            }

            return newEntries.Count;
        }

        public async Task<TimeEntry> UpdateEntry(RecordableTime inputEntry, int? transNo = null)
        {
            if (inputEntry.StaffId == null) throw new HttpResponseException(HttpStatusCode.BadRequest);
            if (!inputEntry.EntryNo.HasValue) return null;
            TimeEntry result;

            var dateToConsider = inputEntry.Start ?? inputEntry.EntryDate;

            var list = (await _chainUpdater.GetDownwardChain(inputEntry.StaffId.Value, dateToConsider, inputEntry.EntryNo.Value)).ToList();
            var firstEntry = list.First();

            inputEntry = inputEntry.AdjustDataForWipCalculation(inputEntry.ParentEntryNo.HasValue ? firstEntry.TimeCarriedForward : null);
            _mapper.Map(inputEntry, firstEntry);

            if (inputEntry.Start?.Date != inputEntry.EntryDate)
            {
                firstEntry.StartTime = inputEntry.EntryDate.Add(firstEntry.StartTime.GetValueOrDefault().TimeOfDay);
                firstEntry.FinishTime = inputEntry.EntryDate.Add(firstEntry.FinishTime.GetValueOrDefault().TimeOfDay);
            }

            if (inputEntry.IsCostableEntry)
            {
                var costedEntry = await _valueTime.For(inputEntry, _cultureResolver.Resolve());
                _mapper.Map(costedEntry, firstEntry);
                _splitUpdater.UpdateSplits(firstEntry, costedEntry?.DebtorSplits);
                
                result = _mapper.Map<TimeEntry>(firstEntry);
                if (costedEntry?.DebtorSplits != null & costedEntry?.DebtorSplits?.Count > 0)
                {
                    result.DebtorSplits.AddRange(costedEntry.DebtorSplits);
                }
            }
            else
            {
                result = _mapper.Map<TimeEntry>(firstEntry);
            }

            _chainUpdater.UpdateData(list, firstEntry, true, true);
            if (transNo != null)
                firstEntry.TransactionId = transNo;

            await _dbContext.SaveChangesAsync();
            
            return result;
        }

        public async Task<bool> UpdateDate(RecordableTime input)
        {
            if (!input.StaffId.HasValue) throw new ArgumentNullException(nameof(input.StaffId));
            if (!input.EntryNo.HasValue) throw new ArgumentNullException(nameof(input.EntryNo));
            if (!input.Start.HasValue) throw new ArgumentNullException(nameof(input.Start));

            var list = (await _chainUpdater.GetDownwardChain(input.StaffId.Value, input.Start.Value.Date, input.EntryNo.Value)).ToList();

            var firstEntry = list.First();
            await _wipWarningCheck.For(firstEntry.CaseId, firstEntry.NameNo);

            firstEntry.StartTime = input.EntryDate.Add(firstEntry.StartTime.GetValueOrDefault().TimeOfDay);
            firstEntry.FinishTime = input.EntryDate.Add(firstEntry.FinishTime.GetValueOrDefault().TimeOfDay);
            var inputToBeCosted = _mapper.Map<RecordableTime>(firstEntry);

            var costedEntry = await _valueTime.For(inputToBeCosted.AdjustDataForWipCalculation(), _cultureResolver.Resolve());
            _mapper.Map(costedEntry, firstEntry);
            _splitUpdater.UpdateSplits(firstEntry, costedEntry?.DebtorSplits);

            if (list.Count > 1)
            {
                _chainUpdater.DateUpdated(list, input.EntryDate);
            }

            await _dbContext.SaveChangesAsync();

            return true;
        }

        public async Task<Diary> DeleteEntry(RecordableTime timeEntry)
        {
            if (!timeEntry.StaffId.HasValue) throw new ArgumentNullException(nameof(timeEntry.StaffId));
            if (!timeEntry.EntryNo.HasValue) throw new ArgumentNullException(nameof(timeEntry.EntryNo));

            var diaries = (await _chainUpdater.GetWholeChain(timeEntry.StaffId.Value, timeEntry.EntryDate.Date, timeEntry.EntryNo.Value)).ToList();

            var details = await RemoveEntryFromChain(diaries, timeEntry);

            return details.diaryToRemove;
        }

        public async Task<bool> DeleteChainFor(RecordableTime entry)
        {
            if (!entry.StaffId.HasValue) throw new ArgumentNullException(nameof(entry.StaffId));
            if (!entry.EntryNo.HasValue) throw new ArgumentNullException(nameof(entry.EntryNo));
            if (!entry.Start.HasValue) throw new ArgumentNullException(nameof(entry.Start));

            var chain = await _chainUpdater.GetWholeChain(entry.StaffId.Value, entry.Start.Value.Date, entry.EntryNo.Value);

            var list = chain.ToList();
            list.ForEach(d => _dbContext.Set<Diary>().Remove(d));

            await _dbContext.SaveChangesAsync();

            return true;
        }

        public async Task<(Diary diaryToRemove, Diary newLastChild)> RemoveEntryFromChain(IEnumerable<Diary> chain, RecordableTime timeEntry)
        {
            if (!timeEntry.EntryNo.HasValue) throw new ArgumentNullException(nameof(timeEntry.EntryNo));

            var (diaryToRemove, newLastChild) = await _chainUpdater.RemoveEntryFromChain(chain.ToList(), timeEntry.EntryNo.Value);

            if (diaryToRemove != null)
            {
                _splitUpdater.PurgeSplits(diaryToRemove);
                _dbContext.Set<Diary>().Remove(diaryToRemove);
            }

            if (newLastChild != null)
            {
                var costableTime = _mapper.Map<RecordableTime>(newLastChild);
                costableTime.EntryDate = newLastChild.StartTime.GetValueOrDefault().Date;
                var costedTime = await _valueTime.For(costableTime.AdjustDataForWipCalculation(), _cultureResolver.Resolve());
                _mapper.Map(costedTime, newLastChild);
                _splitUpdater.UpdateSplits(newLastChild, costedTime?.DebtorSplits);
            }

            await _dbContext.SaveChangesAsync();

            return (diaryToRemove, newLastChild);
        }

        public async Task<int> BatchDelete(int forStaffNameId, IEnumerable<int> entryNos)
        {
            var forDeletion = entryNos as int[] ?? entryNos.ToArray();
            var count = await GetDiaryQuery(forStaffNameId, forDeletion).DeleteAsync();

            return count;
        }

        public async Task<int> BatchUpdateNarratives(int forStaffNameId, IEnumerable<int> entryNos, string narrativeText = null, short? narrativeNo = null)
        {
            var entryNumbers = entryNos as int[] ?? entryNos.ToArray();
            var count = 0;
            using (var tcs = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled))
            {
                count = await _dbContext.UpdateAsync(GetDiaryQuery(forStaffNameId, entryNumbers),
                                                     _ => new Diary
                                                     {
                                                         NarrativeNo = narrativeNo,
                                                         LongNarrative = !string.IsNullOrEmpty(narrativeText) && narrativeText.Length > 254 ? narrativeText : null,
                                                         ShortNarrative = !string.IsNullOrEmpty(narrativeText) && narrativeText.Length <= 254 ? narrativeText : null
                                                     });

                if (count > 0)
                {
                    await _dbContext.UpdateAsync(GetDebtorSplitQuery(forStaffNameId, entryNumbers),
                                                 _ => new DebtorSplitDiary
                                                 {
                                                     NarrativeNo = narrativeNo,
                                                     Narrative = narrativeText
                                                 });
                }

                tcs.Complete();
            }

            return count;
        }

        IQueryable<Diary> GetDiaryQuery(int staffId, IEnumerable<int> entryNos)
        {
            return _dbContext.Set<Diary>().Where(_ => _.EmployeeNo == staffId && entryNos.Contains(_.EntryNo));
        }

        IQueryable<DebtorSplitDiary> GetDebtorSplitQuery(int staffId, ICollection<int> entryNos)
        {
            return _dbContext.Set<DebtorSplitDiary>().Where(_ => _.EmployeeNo == staffId && entryNos.Contains(_.EntryNo.Value));
        }
    }
}