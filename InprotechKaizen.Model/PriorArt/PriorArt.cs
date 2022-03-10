using System;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.PriorArt
{
    [Table("SEARCHRESULTS")]
    public class PriorArt
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        [Obsolete("For persistance only.")]
        public PriorArt()
        {
            CitedPriorArt = new Collection<PriorArt>();
            SourceDocuments = new Collection<PriorArt>();
        }

#pragma warning disable CS0618 // Type or member is obsolete
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public PriorArt(string officialNumber, Country country, string kind = null) : this()
#pragma warning restore CS0618 // Type or member is obsolete
        {
            OfficialNumber = officialNumber;
            Country = country;
            Kind = kind;
        }

#pragma warning disable CS0618 // Type or member is obsolete
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public PriorArt(TableCode sourceType, Country issuingCountry) : this()
#pragma warning restore CS0618 // Type or member is obsolete
        {
            if(sourceType == null) throw new ArgumentNullException("sourceType");

            SourceType = sourceType;
            IssuingCountry = issuingCountry;
        }

        [Key]
        [Column("PRIORARTID")]
        public int Id { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [MaxLength(3)]
        [Column("ISSUINGCOUNTRY")]
        public string IssuingCountryId { get; set; }
        
        [MaxLength(36)]
        [Column("OFFICIALNO")]
        public string OfficialNumber { get; set; }

        [MaxLength(254)]
        [Column("KINDCODE")]
        public string Kind { get; set; }

        [Column("TITLE")]
        public string Title { get; set; }

        [Column("CLASS")]
        public string Classes { get; set; }

        [Column("SUBCLASS")]
        public string SubClasses { get; set; }

        [Column("CITATION")]
        public string Citation { get; set; }

        [Column("ISSOURCEDOCUMENT")]
        public bool IsSourceDocument { get; set; }

        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("ABSTRACT")]
        public string Abstract { get; set; }

        [Column("INVENTORNAME")]
        public string Name { get; set; }

        [MaxLength(254)]
        [Column("REFPAGES")]
        public string RefDocumentParts { get; set; }

        [Column("PUBLICATION")]
        public string Publication { get; set; }

        [Column("TRANSLATION")]
        [ForeignKey("TranslationType")]
        public int? Translation { get; set; }

        [Column("PUBLICATIONDATE")]
        public DateTime? PublishedDate { get; set; }

        [Column("PRIORITYDATE")]
        public DateTime? PriorityDate { get; set; }

        [Column("GRANTEDDATE")]
        public DateTime? GrantedDate { get; set; }

        [Column("PTOCITEDDATE")]
        public DateTime? PtoCitedDate { get; set; }

        [Column("APPFILEDDATE")]
        public DateTime? ApplicationFiledDate { get; set; }

        [Column("SOURCE")]
        [ForeignKey("SourceType")]
        public int? SourceTypeId { get; set; }

        [Column("PATENTRELATED")]
        public bool? IsIpDocument { get; set; }

        [MaxLength(256)]
        [Column("IMPORTEDFROM")]
        public string ImportedFrom { get; set; }

        [MaxLength(256)]
        [Column("CORRELATIONID")]
        public string CorrelationId { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }

        [Column("ISSUEDDATE")]
        public DateTime? ReportIssued { get; set; }
        
        [Column("RECEIVEDDATE")]
        public DateTime? ReportReceived { get; set; }

        [MaxLength(254)]
        [Column("COMMENTS")]
        public string Comments { get; set; }

        [Column("CITY")]
        public string City { get; set; }

        [Column("PUBLISHER")]
        public string Publisher { get; set; }

        [ForeignKey("CountryId")]
        public virtual Country Country { get; protected set; }
        
        [ForeignKey("IssuingCountryId")]
        public virtual Country IssuingCountry { get; protected set; }

        public virtual TableCode SourceType { get; protected set; }

        public virtual TableCode TranslationType { get; protected set; }

        public virtual Collection<PriorArt> SourceDocuments { get; set; }

        public virtual Collection<PriorArt> CitedPriorArt { get; set; }

        public virtual Collection<CaseSearchResult> CaseSearchResult { get; set; }
    }
}