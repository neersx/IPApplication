namespace InprotechKaizen.Model.Components.Accounting.Billing.Presentation
{
    public class BillFormat
    {
        public int? BillFormatId { get; set; }
        public string FormatName { get; set; }
        public string Action { get; set; }
        public string Description { get; set; }
        public string BillFormatReport { get; set; }
        public string CaseType { get; set; }
        public int? ConsolidateByChargeType { get; set; }
        public int? ConsolidateDiscounts { get; set; }
        public int? ConsolidateMargins { get; set; }
        public int? ConsolidateOverheadRecoveries { get; set; }
        public int? ConsolidatePaidDisbursements { get; set; }
        public int? ConsolidateServiceCharges { get; set; }
        public string DiscountWipCode { get; set; }
        public string MarginWipCode { get; set; }
        public int? CoveringLetterId { get; set; }
        public int? DebitNoteId { get; set; }
        public int? DocumentTypeId { get; set; }
        public int? AreDetailsRequired { get; set; }
        public int? StaffId { get; set; }
        public int? EntityId { get; set; }
        public string ExpenseGroupTitle { get; set; }
        public int? LanguageId { get; set; }
        public int? NameId { get; set; }
        public int? OfficeId { get; set; }
        public string PropertyType { get; set; }
        public bool? IsRenewalWipOnly { get; set; }
        public bool? IsSingleCaseOnly { get; set; }
        public int? SortCase { get; set; }
        public int? SortCaseMode { get; set; }
        public int? SortDate { get; set; }
        public int? SortWipCategory { get; set; }
        public int? SortCaseTitle { get; set; }
        public int? SortCaseDebtorRef { get; set; }
        public int? SortTaxCode { get; set; }
    }
}