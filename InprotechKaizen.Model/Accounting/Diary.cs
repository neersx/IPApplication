using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Accounting
{
    [Table("DIARY")]
    public class Diary
    {
        [Key]
        [Column("EMPLOYEENO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EmployeeNo { get; set; }

        [Key]
        [Column("ENTRYNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntryNo { get; set; }

        [StringLength(6)]
        [Column("ACTIVITY")]
        public string Activity { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("NAMENO")]
        public int? NameNo { get; set; }

        [Column("STARTTIME")]
        public DateTime? StartTime { get; set; }

        [Column("FINISHTIME")]
        public DateTime? FinishTime { get; set; }

        [Column("TOTALTIME")]
        public DateTime? TotalTime { get; set; }

        [Column("TOTALUNITS")]
        public short? TotalUnits { get; set; }

        [Column("TIMECARRIEDFORWARD")]
        public DateTime? TimeCarriedForward { get; set; }

        [Column("UNITSPERHOUR")]
        public short? UnitsPerHour { get; set; }

        [Column("TIMEVALUE")]
        public decimal? TimeValue { get; set; }

        [Column("CHARGEOUTRATE")]
        public decimal? ChargeOutRate { get; set; }

        [Column("WIPENTITYNO")]
        public int? WipEntityId { get; set; }

        [Column("TRANSNO")]
        public int? TransactionId { get; set; }

        [Column("WIPSEQNO")]
        public short? WipSeqNo { get; set; }

        [StringLength(254)]
        [Column("NOTES")]
        public string Notes { get; set; }

        [Column("NARRATIVENO")]
        public short? NarrativeNo { get; set; }

        [StringLength(254)]
        [Column("SHORTNARRATIVE")]
        public string ShortNarrative { get; set; }

        [Column("LONGNARRATIVE", TypeName = "nText")]
        public string LongNarrative { get; set; }

        [Column("DISCOUNTVALUE")]
        public decimal? DiscountValue { get; set; }

        [StringLength(3)]
        [Column("FOREIGNCURRENCY")]
        public string ForeignCurrency { get; set; }

        [Column("FOREIGNVALUE")]
        public decimal? ForeignValue { get; set; }

        [Column("EXCHRATE")]
        [DataType("decimal(11,4)")]
        public decimal? ExchRate { get; set; }

        [Column("FOREIGNDISCOUNT")]
        public decimal? ForeignDiscount { get; set; }

        [Column("QUOTATIONNO")]
        public int? QuotationNo { get; set; }

        [Column("PARENTENTRYNO")]
        public int? ParentEntryNo { get; set; }

        [Column("COSTCALCULATION1")]
        public decimal? CostCalculation1 { get; set; }

        [Column("COSTCALCULATION2")]
        public decimal? CostCalculation2 { get; set; }

        [Column("PRODUCTCODE")]
        public int? ProductCode { get; set; }

        [Column("ISTIMER")]
        public decimal IsTimer { get; set; }

        [Column("MARGINNO")]
        public int? MarginId { get; set; }

        [Column("SHORTNARRATIVE_TID")]
        public int? ShortNarrativeTId { get; set; }

        [Column("LONGNARRATIVE_TID")]
        public int? LongNarrativeTId { get; set; }

        [Column("CREATEDON")]
        public DateTime CreatedOn { get; set; }

        [Column("TIMERSTARTED")]
        public DateTime? TimerStarted { get; set; }

        public virtual Case Case { get; set; }

        [ForeignKey("NarrativeNo")]
        public virtual Narrative Narrative { get; set; }

        [ForeignKey("NameNo")]
        public virtual Name Name { get; set; }

        [ForeignKey("Activity")]
        public virtual WipTemplate ActivityDetail { get; set; }

        public IList<DebtorSplitDiary> DebtorSplits { get; set; }
    }

    public static class DiaryEx
    {
        public static IEnumerable<Diary> GetWholeChainFor(this IEnumerable<Diary> diaryEntries, int entryNo)
        {
            var result = new List<Diary>();

            var entries = diaryEntries as Diary[] ?? diaryEntries.ToArray();

            var entry = entries.SingleOrDefault(_ => _.EntryNo == entryNo);
            if (entry == null)
                return result.ToArray();

            while (entry != null)
            {
                entry = entries.SingleOrDefault(_ => _.ParentEntryNo == entry.EntryNo);
                if (entry != null)
                {
                    result.Insert(0, entry);
                }
            }

            result.AddRange(entries.GetDownwardChainFor(entryNo));

            return result.ToArray();
        }

        public static IEnumerable<Diary> GetDownwardChainFor(this IEnumerable<Diary> diaryEntries, int entryNo)
        {
            var result = new List<Diary>();

            var entries = diaryEntries as Diary[] ?? diaryEntries.ToArray();

            var childEntry = entries.SingleOrDefault(_ => _.EntryNo == entryNo);
            if (childEntry == null)
                return result.ToArray();

            while (childEntry != null)
            {
                result.Add(childEntry);

                childEntry = childEntry.ParentEntryNo.HasValue ? entries.SingleOrDefault(_ => _.EntryNo == childEntry.ParentEntryNo) : null;
            }

            return result.ToArray();
        }

        public static IQueryable<Diary> ExcludePosted(this IQueryable<Diary> diaryEntries)
        {
            return diaryEntries.Where(_ => _.TransactionId == null);
        }

        public static IQueryable<Diary> ExcludeContinuedParentEntries(this IQueryable<Diary> diaryEntries)
        {
            return diaryEntries.Where(_ => _.TotalTime != null);
        }

        public static IQueryable<Diary> ExcludeEntriesWithNoDuration(this IQueryable<Diary> diaryEntries)
        {
            var baseDate = new DateTime(1899, 1, 1);
            return diaryEntries.Where(_ => _.TotalTime != null && _.TotalTime.Value != baseDate);
        }

        public static IQueryable<Diary> ExcludeRunningTimerEntries(this IQueryable<Diary> diaryEntries)
        {
            return diaryEntries.Where(_ => _.IsTimer != 1);
        }

        public static IQueryable<Diary> ExcludeEntriesWithoutActivity(this IQueryable<Diary> diaryEntries)
        {
            return diaryEntries.Where(_ => _.Activity != null);
        }

        public static IQueryable<Diary> ExcludeEntriesWithoutCase(this IQueryable<Diary> diaryEntries, bool isCaseOnlySet)
        {
            return isCaseOnlySet ? diaryEntries.Where(_ => _.CaseId != null) : diaryEntries.Where(_ => _.CaseId != null || _.NameNo != null);
        }

        public static IQueryable<Diary> ExcludeEntriesWithoutRate(this IQueryable<Diary> diaryEntries, bool isRateMandatorySet)
        {
            return isRateMandatorySet ? diaryEntries.Where(_ => _.ChargeOutRate != null) : diaryEntries;
        }

        public static IQueryable<Diary> ApplyDateFilters(this IQueryable<Diary> diaryEntries, DateTime? fromDate, DateTime? toDate)
        {
            if (fromDate == null && toDate == null)
                return diaryEntries;

            var filtered = diaryEntries;
            if (fromDate != null)
            {
                var startDate = fromDate.GetValueOrDefault().Date;
                filtered = diaryEntries.Where(d => DbFuncs.TruncateTime(d.StartTime) >= startDate);
            }

            if (toDate == null) return filtered;

            var endDate = toDate.GetValueOrDefault().Date;
            return filtered.Where(d => DbFuncs.TruncateTime(d.StartTime) <= endDate);
        }

        public static IQueryable<Diary> ApplyEntityFilter(this IQueryable<Diary> diaryEntries, int? entityId)
        {
            return !entityId.HasValue
                ? diaryEntries
                : diaryEntries.Where(d => d.WipEntityId == entityId);
        }

        public static IQueryable<Diary> ApplyCaseFilter(this IQueryable<Diary> diaryEntries, int?[] caseIds)
        {
            return caseIds == null || !caseIds.Any()
                ? diaryEntries
                : diaryEntries.Where(d => d.CaseId != null && caseIds.Contains(d.CaseId));
        }

        public static IQueryable<Diary> ApplyPostedUnpostedFilter(this IQueryable<Diary> diaryEntries, bool isPostedOnly, bool isUnpostedOnly)
        {
            return !isPostedOnly && !isUnpostedOnly
                ? diaryEntries
                : isPostedOnly
                    ? diaryEntries.Where(d => d.TransactionId != null && d.WipEntityId != null)
                    : diaryEntries.Where(d => d.TransactionId == null && d.WipEntityId == null);
        }

        public static IQueryable<Diary> ApplyActivityFilter(this IQueryable<Diary> diaryEntries, string activityCode)
        {
            return string.IsNullOrWhiteSpace(activityCode)
                ? diaryEntries
                : diaryEntries.Where(_ => _.Activity == activityCode);
        }

        public static IQueryable<Diary> ApplyNameFilter(this IQueryable<Diary> diaryEntries, int? nameId, bool asDebtor, bool asInstructor)
        {
            if (!nameId.HasValue)
                return diaryEntries;

            return diaryEntries.Where(d => asDebtor && d.NameNo == nameId ||
                                           asInstructor && d.NameNo == null && d.Case.CaseNames.Any(_ => _.NameTypeId == KnownNameTypes.Instructor && _.NameId == nameId));
        }

        public static IQueryable<Diary> ApplyNarrativeFilter(this IQueryable<Diary> diaryEntries, string narrativeSearch)
        {
            return string.IsNullOrWhiteSpace(narrativeSearch)
                ? diaryEntries
                : diaryEntries.Where(_ => DbFuncs.GetTranslation(_.ShortNarrative, _.LongNarrative, _.LongNarrativeTId ?? _.ShortNarrativeTId, string.Empty).Contains(narrativeSearch));
        }

        public static void ClearParentValues(this Diary parentEntry)
        {
            parentEntry.TimeCarriedForward = null;
            parentEntry.TotalTime = null;
            parentEntry.TotalUnits = null;
            parentEntry.TimeValue = null;
            parentEntry.DiscountValue = null;
            parentEntry.ForeignValue = null;
            parentEntry.ForeignDiscount = null;
            parentEntry.CostCalculation1 = null;
            parentEntry.CostCalculation2 = null;
        }

        public static void UpdateTimeCarriedForwardForChild(this Diary childEntry)
        {
            if (childEntry.ParentEntryNo == null)
            {
                childEntry.TimeCarriedForward = null;
                return;
            }

            childEntry.TimeCarriedForward = childEntry.TimeCarriedForward.GetValueOrDefault().TimeOfDay != TimeSpan.Zero ? childEntry.TimeCarriedForward : childEntry.TotalTime;
        }

        public static int GetNewEntryNoFor(this IQueryable<Diary> diaryTable, int staffNameId)
        {
            return diaryTable.Where(_ => _.EmployeeNo == staffNameId).Select(_ => _.EntryNo).DefaultIfEmpty(-1).Max() + 1;
        }

        public static bool TrySetFinishTimeForTimer(this Diary diary, DateTime? totalTime)
        {
            if (!diary.StartTime.HasValue)
                return false;

            var totalTimeSpan = totalTime?.TimeOfDay;
            if (totalTimeSpan?.TotalMilliseconds < 0)
                return false;

            if (totalTimeSpan == null || totalTimeSpan.Value.Days > 0 || diary.StartTime.Value.AddTicks(totalTimeSpan.Value.Ticks).Date != diary.StartTime.Value.Date)
            {
                totalTimeSpan = diary.StartTime.Value.Date.Add(new TimeSpan(23, 59, 59)).Subtract(diary.StartTime.Value);
            }

            diary.FinishTime = diary.StartTime.Value.AddTicks(totalTimeSpan.Value.Ticks);
            diary.TotalTime = new DateTime(1899, 1, 1).AddTicks(totalTimeSpan.Value.Ticks);

            return true;
        }

        public static bool TryStopTimer(this Diary diary, DateTime stopTime)
        {
            if (!diary.StartTime.HasValue)
                return false;

            var totalTimeSpan = stopTime.TimeOfDay;
            if (!stopTime.Date.Equals(diary.StartTime.Value.Date))
            {
                totalTimeSpan = new TimeSpan(23, 59, 59);
            }

            diary.FinishTime = diary.StartTime.Value.Date.AddTicks(totalTimeSpan.Ticks);
            diary.TotalTime = new DateTime(1899, 1, 1).AddTicks(diary.FinishTime.Value.Subtract(diary.StartTime.Value).Ticks);

            return true;
        }
    }
}