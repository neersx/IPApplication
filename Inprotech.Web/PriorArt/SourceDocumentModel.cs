using System;

namespace Inprotech.Web.PriorArt
{
    public class SourceDocumentModel
    {
        public SourceDocumentModel(InprotechKaizen.Model.PriorArt.PriorArt sourceDocument)
        {
            if(sourceDocument == null) throw new ArgumentNullException("sourceDocument");

            SourceId = sourceDocument.Id;
            Publisher = sourceDocument.Publisher;
            City = sourceDocument.City;
            IssuingJurisdiction = new SourceJurisdiction {Key = sourceDocument.IssuingCountry?.Id, Value = sourceDocument.IssuingCountry?.Name};
            Country = new SourceJurisdiction {Key = sourceDocument.Country?.Id, Value = sourceDocument.Country?.Name};
            Publication = sourceDocument.Publication;
            Classes = sourceDocument.Classes;
            SubClasses = sourceDocument.SubClasses;
            ReportIssued = sourceDocument.ReportIssued;
            ReportReceived = sourceDocument.ReportReceived;
            Comments = sourceDocument.Comments;
            SourceType = new SourceType {Id = sourceDocument.SourceType?.Id, Name = sourceDocument.SourceType?.Name};
            IsSourceDocument = sourceDocument.IsSourceDocument;
            IsIpDocument = sourceDocument.IsIpDocument;
            KindCode = sourceDocument.Kind;
            Title = sourceDocument.Title;
            OfficialNumber = sourceDocument.OfficialNumber;
            Citation = sourceDocument.Citation;
            ApplicationFiledDate = sourceDocument.ApplicationFiledDate;
            PublishedDate = sourceDocument.PublishedDate;
            GrantedDate = sourceDocument.GrantedDate;
            PriorityDate = sourceDocument.PriorityDate;
            PtoCitedDate = sourceDocument.PtoCitedDate;
            InventorName = sourceDocument.Name;
            ReferenceParts = sourceDocument.RefDocumentParts;
            TranslationType = new TranslationType {Key = sourceDocument.TranslationType?.Id.ToString(), Value = sourceDocument.TranslationType?.Name};
            Abstract = sourceDocument.Abstract;
            Description = sourceDocument.Description;

            if (sourceDocument.Description?.Length > 100)
            {
                sourceDocument.Description = sourceDocument.Description.Substring(0, 100) + "...";
            }
            SearchDescription = string.Join(
                                      " ",
                                      new[]
                                      {
                                          sourceDocument.IssuingCountry != null
                                              ? sourceDocument.IssuingCountry.Id
                                              : string.Empty,
                                          sourceDocument.Description != null ? $"({sourceDocument.Description})" : sourceDocument.Description
                                      });

            if(string.IsNullOrWhiteSpace(SearchDescription))
                SearchDescription = "Description for this source document is not available";
        }

        public int SourceId { get; set; }
        public string Publisher { get; set; }
        public string City { get; set; }
        public SourceJurisdiction IssuingJurisdiction { get; set; }
        public SourceJurisdiction Country { get; set; }
        public string Publication { get; set; }
        public string Classes { get; set; }
        public string SubClasses { get; set; }
        public DateTime? ReportIssued { get; set; }
        public DateTime? ReportReceived { get; set; }
        public string Comments { get; set; }
        public SourceType SourceType { get; set; }
        public string Description { get; set; }
        public string SearchDescription { get; set; }
        public bool IsSourceDocument { get; set; }
        public bool? IsIpDocument { get; set; }
        public string KindCode { get; set; }
        public string Title { get; set; }
        public string OfficialNumber { get; set; }
        public string Citation { get; set; }
        public DateTime? ApplicationFiledDate { get; set; }
        public DateTime? PublishedDate { get; set; }
        public DateTime? GrantedDate { get; set; }
        public DateTime? PriorityDate { get; set; }
        public DateTime? PtoCitedDate{ get; set; }
        public string InventorName { get; set; }
        public string ReferenceParts { get; set; }
        public TranslationType TranslationType { get; set; }
        public string Abstract { get; set; }
    }

    public class SourceType
    {
        public int? Id { get; set; }
        public string Name { get; set; }
    }

    public class SourceJurisdiction
    {
        public string Key { get; set; }
        public string Value { get; set; }
    }

    public class TranslationType
    {
        public string Key { get; set; }
        public string Value { get; set; }
    }
}