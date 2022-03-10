namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.References
{
    public class BillReference
    {
        public int ItemEntityId { get; set; }
        public int ItemTransactionId { get; set; }
        public string CaseTitle { get; set; }
        public string ReferenceText { get; set; }
        public string BillScope { get; set; }
        public string Regarding { get; set; }
        public string StatementText { get; set; }
    }
}
