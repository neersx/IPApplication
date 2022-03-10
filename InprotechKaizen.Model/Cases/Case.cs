using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
#pragma warning disable 618

namespace InprotechKaizen.Model.Cases
{
    [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Case")]
    [Table("CASES")]
    public class Case
    {
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        [Obsolete("For persistence only.")]
        public Case()
        {
            OfficialNumbers = new Collection<OfficialNumber>();
            OpenActions = new Collection<OpenAction>();
            CaseNames = new Collection<CaseName>();
            CaseEvents = new Collection<CaseEvent>();
            CaseImages = new Collection<CaseImage>();
            CaseLocations = new Collection<CaseLocation>();
            FileRequests = new Collection<FileRequest>();
            CaseTexts = new Collection<CaseText>();
            PendingRequests = new Collection<CaseActivityRequest>();
            History = new Collection<CaseActivityHistory>();
            CaseListMemberships = new Collection<CaseListMember>();
            Activities = new Collection<Activity>();
            CaseTexts = new Collection<CaseText>();
            RelatedCases = new Collection<RelatedCase>();
            ClassFirstUses = new Collection<ClassFirstUse>();
            CaseChecklists = new Collection<CaseChecklist>();
            CaseDesignElements = new Collection<DesignElement>();
        }

        [SuppressMessage("Microsoft.Usage", "CS0618")]
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Case(string irn, Country country, CaseType caseType, PropertyType propertyType,
                    CaseProperty property = null) : this()
        {
            if (string.IsNullOrWhiteSpace(irn)) throw new ArgumentException("A valid irn is required.");
            if (caseType == null) throw new ArgumentNullException(nameof(caseType));

            Irn = irn;
            Country = country ?? throw new ArgumentNullException(nameof(country));
            PropertyType = propertyType ?? throw new ArgumentNullException(nameof(propertyType));
            Property = property;

            SetCaseType(caseType);
        }

        public Case(int id, string irn, Country country, CaseType caseType, PropertyType propertyType,
                      CaseProperty property = null) : this(irn, country, caseType, propertyType, property)
        {
            Id = id;
        }

        [Column("CASEID")]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; internal set; }

        [Required]
        [MaxLength(30)]
        [Column("IRN")]
        public string Irn { get; set; }

        [MaxLength(254)]
        [Column("TITLE")]
        public string Title { get; set; }

        [MaxLength(254)]
        [Column("LOCALCLASSES")]
        public string LocalClasses { get; set; }

        [MaxLength(254)]
        [Column("INTCLASSES")]
        public string IntClasses { get; set; }

        [Column("NOINSERIES")]
        public short? NoInSeries { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("LOCALCLIENTFLAG")]
        public decimal? LocalClientFlag { get; set; }

        [Required]
        [MaxLength(1)]
        [Column("CASETYPE")]
        public string TypeId { get; set; }

        [MaxLength(2)]
        [Column("CASECATEGORY")]
        public string CategoryId { get; set; }

        [MaxLength(2)]
        [Column("SUBTYPE")]
        public string SubTypeId { get; set; }

        [MaxLength(36)]
        [Column("CURRENTOFFICIALNO")]
        public string CurrentOfficialNumber { get; set; }

        [MaxLength(30)]
        [Column("STEM")]
        public string Stem { get; set; }

        [Column("TITLE_TID")]
        public int? TitleTId { get; set; }

        [Column("IPODELAY")]
        public int? IpoDelay { get; set; }

        [Column("APPLICANTDELAY")]
        public int? ApplicantDelay { get; set; }

        [Column("IPOPTA")]
        public int? IpoPta { get; set; }

        [Required]
        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [Required]
        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [Column("EXTENDEDRENEWALS")]
        public int? ExtendedRenewals { get; set; }

        [Column("REPORTTOTHIRDPARTY")]
        public decimal? ReportToThirdParty { get; set; }

        [MaxLength(1)]
        [Column("STOPPAYREASON")]
        public string StopPayReason { get; set; }

        [Column("OFFICEID")]
        public int? OfficeId { get; set; }

        [MaxLength(20)]
        [Column("FAMILY")]
        public string FamilyId { get; set; }

        [MaxLength(6)]
        [Column("PROFITCENTRECODE")]
        public string ProfitCentreCode { get; set; }

        [Column("TYPEOFMARK")]
        public int? TypeOfMarkId { get; set; }

        [MaxLength(80)]
        [Column("PURCHASEORDERNO")]
        public string PurchaseOrderNo { get; set; }

        [Column("ENTITYSIZE")]
        public int? EntitySizeId { get; set; }

        [Column("STATUSCODE")]
        public short? StatusCode { get; set; }

        [Column("BUDGETAMOUNT")]
        public decimal? BudgetAmount { get; set; }

        [Column("BUDGETREVISEDAMT")]
        public decimal? BudgetRevisedAmt { get; set; }

        [Column("BUDGETSTARTDATE")]
        public DateTime? BudgetStartDate { get; set; }

        [Column("BUDGETENDDATE")]
        public DateTime? BudgetEndDate { get; set; }

        [Column("TAXCODE")]
        public string TaxCode { get; set; }

        public virtual ICollection<OpenAction> OpenActions { get; set; }

        public virtual Country Country { get; internal set; }

        [SuppressMessage("Microsoft.Naming", "CA1721:PropertyNamesShouldNotMatchGetMethods")]
        public virtual CaseType Type { get; internal set; }

        public virtual PropertyType PropertyType { get; internal set; }

        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Property")]
        public virtual CaseProperty Property { get; internal set; }

        public virtual Status CaseStatus { get; set; }

        public virtual ICollection<OfficialNumber> OfficialNumbers { get; protected set; }

        public virtual ICollection<CaseEvent> CaseEvents { get; protected set; }

        public virtual CaseCategory Category { get; set; }

        public virtual ProfitCentre ProfitCentre { get; protected set; }

        public virtual SubType SubType { get; set; }

        public virtual Family Family { get; set; }

        public virtual Office Office { get; set; }

        public virtual TableCode TypeOfMark { get; set; }

        public virtual TableCode EntitySize { get; set; }

        public virtual ICollection<CaseName> CaseNames { get; protected set; }

        public virtual ICollection<CaseImage> CaseImages { get; set; }

        public virtual ICollection<CaseLocation> CaseLocations { get; protected set; }

        public virtual ICollection<FileRequest> FileRequests { get; protected set; }

        public virtual ICollection<CaseFilePart> CaseFileParts { get; protected set; }

        public virtual ICollection<CaseActivityRequest> PendingRequests { get; protected set; }

        public virtual ICollection<Activity> Activities { get; protected set; }

        public virtual ICollection<CaseActivityHistory> History { get; protected set; }

        public virtual ICollection<CaseListMember> CaseListMemberships { get; protected set; }

        public virtual ICollection<CaseText> CaseTexts { get; protected set; }

        public virtual ICollection<RelatedCase> RelatedCases { get; protected set; }

        public virtual ICollection<CaseSearchResult> CaseSearchResult { get; protected set; }

        public virtual ICollection<ClassFirstUse> ClassFirstUses { get; protected set; }

        public virtual ICollection<CaseChecklist> CaseChecklists { get; protected set; }

        public virtual ICollection<DesignElement> CaseDesignElements { get; protected set; }
        
        public void SetCaseType(CaseType caseType)
        {
            Type = caseType;
            TypeId = caseType?.Code;
        }

        public void SetCaseCategory(CaseCategory caseCategory)
        {
            Category = caseCategory;
            CategoryId = caseCategory?.CaseCategoryId;
        }
    }
}