using System;
using System.Collections.Generic;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class DebtorSplit
    {
        public int? EntryNo { get; set; }
        public int DebtorNameNo { get; set; }
        public decimal? SplitPercentage { get; set; }
        public decimal? LocalValue { get; set; }
        public decimal? LocalDiscount { get; set; }
        public decimal? ChargeOutRate { get; set; }
        public string ForeignCurrency { get; set; }
        public decimal? ForeignValue { get; set; }
        public decimal? ForeignDiscount { get; set; }
        public decimal? ExchRate { get; set; }
        public short? NarrativeNo { get; set; }
        public string Narrative { get; set; }
        public int? MarginNo { get; set; }
        public decimal? CostCalculation1 { get; set; }
        public decimal? CostCalculation2 { get; set; }
        public short? UnitsPerHour { get; set; }
        public string DebtorName {get; set; }
    }

    public class RecordableTime
    {
        public int? StaffId { get; set; }
        public int? NameKey { get; set; }
        public int? CaseKey { get; set; }
        public DateTime? Start { get; set; }
        public DateTime? Finish { get; set; }
        public DateTime? TotalTime { get; set; }
        public string Activity { get; set; }
        public string NarrativeText { get; set; }
        public string Notes { get; set; }
        public DateTime EntryDate { get; set; }
        public short? NarrativeNo { get; set; }
        public int? EntryNo { get; set; }
        public int? ParentEntryNo { get; set; }
        public DateTime? TimeCarriedForward { get; set; }
        public short? TotalUnits { get; set; }
        public string ActivityKey { get; set; }
        public bool IsSplitDebtorWip { get; set; }
        public List<DebtorSplit> DebtorSplits { get; set; } = new List<DebtorSplit>();
        public string DebtorNameTypeKey { get; set; }

        public RecordableTime AdjustDataForWipCalculation(DateTime? timeCarriedForward = null)
        {
            TotalTime = new DateTime(1899, 1, 1).Add(TotalTime.GetValueOrDefault().TimeOfDay);
            TimeCarriedForward = timeCarriedForward ?? new DateTime(1899, 1, 1).Add(TimeCarriedForward.GetValueOrDefault().TimeOfDay);
            NameKey = CaseKey.HasValue ? null : NameKey;
            if (EntryDate == DateTime.MinValue)
            {
                EntryDate = Start.GetValueOrDefault().Date;
            }

            return this;
        }

        public bool IsCostableEntry => !isTimer && TotalTime.HasValue && TotalTime != new DateTime(1899, 1, 1, 0, 0, 0);

        [JsonIgnore]
        public bool isTimer { get; set; }

        public short? UnitsPerHour { get; set; }
    }

    public class PostedTime : RecordableTime
    {
        public int? TransNo { get; set; }
        public int? EntityNo { get; set; }
        public int? WipSeqNo { get; set; }
    }

    public class SaveTimerData
    {
        public RecordableTime TimeEntry { get; set; }

        public bool StopTimer { get; set; }
    }

    public class StoppedTimerInfo
    {
        public DateTime? Start { get; set; }
        public int? EntryNo { get; set; }
        public int? StaffId { get; set; }
        public DateTime EntryDate { get; set; }
    }
}