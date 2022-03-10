using System;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Presentation
{
    public class BillLineWip
    {
        public int EntityId { get; set; }
        public int TransactionId { get; set; }
        public int WipSeqNo { get; set; }
        public int HistoryLineNo { get; set; }
        public int BillLineNo { get; set; }
        public int? CaseId { get; set; }
        public string WipCategory { get; set; }
        public string Narrative { get; set; }
        public string WipTypeId { get; set; }
        public string WipCode { get; set; }
        public string WipCurrency { get; set; }
        public string Description { get; set; }
        public DateTime TransactionDate { get; set; }
        public DateTime? TotalTime { get; set; }
        public decimal LocalTransValue { get; set; }
        public decimal? ForeignTransValue { get; set; }
        public string ReasonCode { get; set; }
        public int WipCategorySortOrder { get; set; }
        public bool IsDraft { get; set; }
        public bool IsDiscount { get; set; }
        public int? DraftWipRefId { get; set; }
        public bool IsMargin { get; set; }
        public int? SplitWipRefId { get; set; }
        public int UniqueReferenceId { get; set; }
        public decimal? LocalTax { get; set; }
        public decimal? LocalVariation { get; set; }
        public decimal? ForeignVariation { get; set; }
        public bool ShowOnDebitNote { get; set; }
        public decimal? TaxRate { get; set; }
        public string TaxCode { get; set; }
        public int? TotalUnits { get; set; }
        public int? RateNoSortOrder { get; set; }
    }
}