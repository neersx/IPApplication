using System;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class AvailableDocument
    {
        public string ObjectId { get; set; }
        public string FileNameObjectId { get; set; }
        public string DocumentCategory { get; set; }
        public string FileWrapperDocumentCode { get; set; }
        public string DocumentDescription { get; set; }
        public DateTime MailRoomDate { get; set; }
        public int PageCount { get; set; }
    }
}