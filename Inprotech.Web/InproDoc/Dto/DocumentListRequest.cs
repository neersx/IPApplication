using InprotechKaizen.Model.Components.DocumentGeneration;

namespace Inprotech.Web.InproDoc.Dto
{
    public class DocumentListRequest
    {
        public DocumentType DocumentType { get; set; }
        public LetterConsumers UsedBy { get; set; }
        public LetterConsumers NotUsedBy { get; set; }
    }
}