using InprotechKaizen.Model.Components.DocumentGeneration;

namespace Inprotech.Web.InproDoc.Dto
{
    public class Document
    {
        public int DocumentKey { get; set; }
        public string DocumentDescription { get; set; }
        public string DocumentCode { get; set; }
        public string Template { get; set; }
        public bool PlaceOnHold { get; set; }
        public int? DeliveryMethodKey { get; set; }
        public string DeliveryMethodDescription { get; set; }
        public string DefaultFilePath { get; set; }
        public string FileDestinationSP { get; set; }
        public DocumentType DocumentType { get; set; }
        public string SourceFile { get; set; }
        public int? CorrespondenceTypeKey { get; set; }
        public string CorrespondenceTypeDescription { get; set; }
        public int? CoveringLetterKey { get; set; }
        public string CoveringLetterDescription { get; set; }
        public int? EnvelopeKey { get; set; }
        public string EnvelopeDescription { get; set; }
        public bool ForPrimeCasesOnly { get; set; }
        public bool GenerateAsANSI { get; set; }
        public bool MultiCase { get; set; }
        public bool CopiesAllowed { get; set; }
        public int? NbExtraCopies { get; set; }
        public int? SingleCaseLetterKey { get; set; }
        public string SingleCaseLetterDescription { get; set; }
        public bool AddAttachment { get; set; }
        public int? ActivityTypeKey { get; set; }
        public string ActivityTypeDescription { get; set; }
        public int? ActivityCategoryKey { get; set; }
        public string ActivityCategoryDescription { get; set; }
        public string InstructionTypeKey { get; set; }
        public string InstructionTypeDescription { get; set; }
        public string CountryCode { get; set; }
        public string CountryDescription { get; set; }
        public string PropertyType { get; set; }
        public string PropertyTypeDescription { get; set; }
        public bool UsedByCases { get; set; }
        public bool UsedByNames { get; set; }
        public bool UsedByTimeAndBilling { get; set; }
        public bool IsInproDocOnlyTemplate { get; set; }
        public bool IsDGLibOnlyTemplate { get; set; }
        public int? EntryPointTypeKey { get; set; }
        public string EntryPointTypeDescription { get; set; }
        public bool AllFieldsLoaded { get; set; }
    }
}