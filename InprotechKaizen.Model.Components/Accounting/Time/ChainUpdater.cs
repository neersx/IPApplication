using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public interface IChainUpdater
    {
        Task<IEnumerable<Diary>> GetDownwardChain(int staffId, DateTime entryDate, int entryNo);

        Task<IEnumerable<Diary>> GetWholeChain(int staffId, DateTime entryDate, int entryNo);

        Task<(Diary diaryToRemove, Diary newLastChild)> RemoveEntryFromChain(IEnumerable<Diary> enumerable, int entryNoToRemove);

        bool DateUpdated(IEnumerable<Diary> chain, DateTime newDate);

        bool UpdateData(IEnumerable<Diary> enumerable, Diary updateFrom, bool excludeTopEntry = false, bool updateBasics = false);
    }

    public class ChainUpdater : IChainUpdater
    {
        readonly ITimesheetList _timesheetList;

        public ChainUpdater(ITimesheetList timesheetList)
        {
            _timesheetList = timesheetList;
        }

        public async Task<IEnumerable<Diary>> GetDownwardChain(int staffId, DateTime entryDate, int entryNo)
        {
            var recordsForTheDay = await QueryableExtensions.ToArrayAsync<Diary>(_timesheetList.DiaryFor(staffId, entryDate));

            if (recordsForTheDay.Any(_ => _.ParentEntryNo == entryNo))
                throw new ArgumentException("Entry is not the last child. Can not be updated directly");

            if (recordsForTheDay.Count(_ => _.EntryNo == entryNo) != 1)
                throw new ArgumentException("Entry not found");

            return recordsForTheDay.GetDownwardChainFor(entryNo);
        }

        public async Task<IEnumerable<Diary>> GetWholeChain(int staffId, DateTime entryDate, int entryNo)
        {
            var recordsForTheDay = await QueryableExtensions.ToArrayAsync<Diary>(_timesheetList.DiaryFor(staffId, entryDate));

            if (recordsForTheDay.Count(_ => _.EntryNo == entryNo) != 1)
                throw new ArgumentException("Entry not found");

            return recordsForTheDay.GetWholeChainFor(entryNo);
        }

        public bool DateUpdated(IEnumerable<Diary> chain, DateTime newDate)
        {
            var enumerable = chain as Diary[] ?? chain.ToArray();
            var timeEntry = enumerable.First();
            foreach (var parentEntry in enumerable.Except(new[] {timeEntry}))
            {
                parentEntry.StartTime = newDate.Add(parentEntry.StartTime.GetValueOrDefault().TimeOfDay);
                parentEntry.FinishTime = newDate.Add(parentEntry.FinishTime.GetValueOrDefault().TimeOfDay);
                parentEntry.ChargeOutRate = timeEntry.ChargeOutRate;
                parentEntry.ForeignCurrency = timeEntry.ForeignCurrency;
            }

            return true;
        }

        public bool UpdateData(IEnumerable<Diary> enumerable, Diary updateFrom, bool excludeTopEntry = false, bool updateBasics = false)
        {
            var chain = enumerable as Diary[] ?? enumerable.ToArray();
            var recordsToUpdate = excludeTopEntry ? chain.Except(new[] {chain.First()}) : chain;

            foreach (var parentEntry in recordsToUpdate)
            {
                if (updateBasics)
                {
                    parentEntry.CaseId = updateFrom.CaseId;
                    parentEntry.NameNo = updateFrom.NameNo;
                    parentEntry.Activity = updateFrom.Activity;
                    parentEntry.ChargeOutRate = updateFrom.ChargeOutRate;
                    parentEntry.ForeignCurrency = updateFrom.ForeignCurrency;
                }

                parentEntry.NarrativeNo = updateFrom.NarrativeNo;
                parentEntry.LongNarrative = updateFrom.LongNarrative;
                parentEntry.ShortNarrative = updateFrom.ShortNarrative;
                parentEntry.Notes = updateFrom.Notes;
            }

            return true;
        }

        public async Task<(Diary diaryToRemove, Diary newLastChild)> RemoveEntryFromChain(IEnumerable<Diary> enumerable, int entryNoToRemove)
        {
            var chain = enumerable.ToList();
            if (chain.Count == 1)
            {
                return (chain.First(), null);
            }

            var entry = chain.Single(_ => _.EntryNo == entryNoToRemove);
            var changeChainFor = chain.SingleOrDefault(_ => _.ParentEntryNo == entryNoToRemove);
            if (changeChainFor != null)
            {
                changeChainFor.ParentEntryNo = entry.ParentEntryNo;
            }

            entry.ParentEntryNo = null;
            var wasLastChild = chain[0].EntryNo == entry.EntryNo;
            chain.Remove(entry);

            var parentEntry = chain[0];
            if (parentEntry.IsTimer != 1)
            {
                parentEntry.TotalTime = new DateTime(1899, 1, 1).Add(parentEntry.FinishTime.GetValueOrDefault().TimeOfDay - parentEntry.StartTime.GetValueOrDefault().TimeOfDay);
            }

            var totals = chain.Skip(1).Sum(_ => _.FinishTime.GetValueOrDefault().TimeOfDay.TotalSeconds - _.StartTime.GetValueOrDefault().TimeOfDay.TotalSeconds);
            parentEntry.TimeCarriedForward = new DateTime(1899, 1, 1).AddSeconds(totals);

            if (wasLastChild)
            {
                parentEntry.WipEntityId = entry.WipEntityId;
                parentEntry.TransactionId = entry.TransactionId;
                parentEntry.WipSeqNo = entry.WipSeqNo;
            }

            return (entry, parentEntry);
        }
    }
}