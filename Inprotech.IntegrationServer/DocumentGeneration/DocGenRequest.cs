using System;

namespace Inprotech.IntegrationServer.DocumentGeneration
{
    public class DocGenRequest
    {
        public int Id { get; set; }
        public int CaseId { get; set; }
        public DateTime WhenRequested { get; set; }
        public string SqlUser { get; set; }
        public short? LetterId { get; set; }
        public short? DeliveryId { get; set; }
        public int? StatusCode { get; set; }
        public string TemplateName { get; set; }
        public string FileName { get; set; }
        public string XmlFilter { get; set; }
        public short DocumentType { get; set; }
        public int? DeliveryType { get; set; }
        public string LetterName { get; set; }

        public Guid Context { get; set; }
    }
}