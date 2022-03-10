namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public class OpenItemXml
    {
        public int ItemEntityId { get; set; }
        public int ItemTransactionId { get; set; }
        public byte XmlType { get; set; }
        public string ItemXml { get; set; }
    }
}