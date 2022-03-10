namespace Inprotech.Integration.Documents
{
    public class DocumentImport
    {
        public int DocumentId { get; set; }

        public int CaseId { get; set; }

        public string AttachmentName { get; set; }

        public int? AttachmentTypeId { get; set; }

        public int ActivityTypeId { get; set; }

        public int CategoryId { get; set; }

        public int? EventId { get; set; }

        public short? Cycle { get; set; }

        public bool IsPublic { get; set; }
    }
}