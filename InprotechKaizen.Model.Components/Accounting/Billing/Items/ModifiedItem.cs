namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public class ModifiedItem
    {
        public string ChangedItem { get; set; }
        public string OldValue { get; set; }
        public string NewValue { get; set; }
        public string ReasonCode { get; set; }
        public int? CaseId { get; set; }
    }
}