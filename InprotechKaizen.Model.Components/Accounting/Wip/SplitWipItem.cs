using System;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public class SplitWipItem
    {
        public int EntityKey { get; set; }

        public string Entity { get; set; }

        public int TransKey { get; set; }

        public int WipSeqKey { get; set; }

        public DateTime TransDate { get; set; }

        public string WipCode { get; set; }

        public string WipDescription { get; set; }

        public int? CaseKey { get; set; }

        public string CaseReference { get; set; }
        
        public int? StaffKey { get; set; }

        public string StaffName { get; set; }

        public string StaffCode { get; set; }
        
        public decimal Balance { get; set; }
        
        public bool IsCreditWip { get; set; }

        public int? NarrativeKey { get; set; }

        public string NarrativeCode { get; set; }

        public string NarrativeTitle { get; set; }

        public string DebitNoteText { get; set; }
        
        public string ReasonCode { get; set; }
        
        public int? NameKey { get; set; }
        
        public string NameCode { get; set; }
        
        public string Name { get; set; }

        public decimal? LocalAmount { get; set; }
        
        public decimal? ForeignAmount { get; set; }

        public string ProfitCentreKey { get; set; }

        public string ProfitCentreDescription { get; set; }

        public int UniqueKey { get; set; }

        public decimal? SplitPercentage { get; set; }

        public DateTime? LogDateTimeStamp { get; set; }

        public bool IsLastSplit { get; set; }

        public int? NewTransKey { get; set; }

        public int? NewWipSeqKey { get; set; }
    }
}