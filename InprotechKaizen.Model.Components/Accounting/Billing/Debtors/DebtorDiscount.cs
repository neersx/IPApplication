namespace InprotechKaizen.Model.Components.Accounting.Billing.Debtors
{
    public class DebtorDiscount
    {
        public int NameId { get; set; }
        public int Sequence { get; set; }
        public decimal DiscountRate { get; set; }
        public string WipType { get; set; }
        public string WipTypeDescription { get; set; }
        public string WipCategory { get; set; }
        public string WipCategoryDescription { get; set; }
        public string PropertyType { get; set; }
        public string PropertyTypeDescription { get; set; }
        public string Action { get; set; }
        public string ActionDescription { get; set; }
        public int? CaseOwnerId { get; set; }
        public string CaseOwnerName { get; set; }
        public int? StaffId { get; set; }
        public string StaffName { get; set; }
        public string ApplyAs { get; set; }
        public bool BasedOnAmount { get; set; }
        public string WipCode { get; set; }
        public string WipCodeDescription { get; set; }
        public string CaseType { get; set; }
        public string CaseTypeDescription { get; set; }
        public string CountryCode { get; set; }
        public string Country { get; set; }
    }
}