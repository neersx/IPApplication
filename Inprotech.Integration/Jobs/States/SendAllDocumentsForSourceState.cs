namespace Inprotech.Integration.Jobs.States
{
    public class SendAllDocumentsForSourceState
    {
        public int TotalDocuments { get; set; }
        public int SentDocuments { get; set; }
        public bool Acknowledged { get; set; }
    }
}