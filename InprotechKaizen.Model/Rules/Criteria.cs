using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using Action = InprotechKaizen.Model.Cases.Action;

namespace InprotechKaizen.Model.Rules
{
    [Table("CRITERIA")]
    public class Criteria
    {
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Criteria()
        {
            DataEntryTasks = new Collection<DataEntryTask>();
            ValidEvents = new Collection<ValidEvent>();
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("CRITERIANO")]
        public int Id { get; set; }

        [MaxLength(1)]
        [Column("PURPOSECODE")]
        public string PurposeCode { get; set; }

        [Column("CHECKLISTTYPE")]
        public short? ChecklistType { get; set; }

        [Column("PARENTCRITERIA")]
        public int? ParentCriteriaId { get; set; }

        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseTypeId { get; set; }

        [Column("DESCRIPTION")]
        [MaxLength(254)]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        [MaxLength(2)]
        [Column("CASECATEGORY")]
        public string CaseCategoryId { get; set; }

        [Column("ISPUBLIC")]
        public bool IsPublic { get; set; }

        [Column("DATEOFACT")]
        public DateTime? DateOfLaw { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("LOCALCLIENTFLAG")]
        public decimal? LocalClientFlag { get; set; }

        [Column("RULEINUSE")]
        public decimal? RuleInUse { get; set; }

        [Column("USERDEFINEDRULE")]
        public decimal? UserDefinedRule { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [MaxLength(2)]
        [Column("SUBTYPE")]
        public string SubTypeId { get; set; }

        [MaxLength(2)]
        [Column("BASIS")]
        public string BasisId { get; set; }

        [MaxLength(2)]
        [Column("ACTION")]
        public string ActionId { get; set; }

        [Column("CASEOFFICEID")]
        public int? OfficeId { get; set; }

        [Column("PROPERTYUNKNOWN")]
        public decimal? PropertyUnknown { get; set; }

        [Column("COUNTRYUNKNOWN")]
        public decimal? CountryUnknown { get; set; }

        [Column("CATEGORYUNKNOWN")]
        public decimal? CategoryUnknown { get; set; }

        [Column("SUBTYPEUNKNOWN")]
        public decimal? SubtypeUnknown { get; set; }

        [Column("TABLECODE")]
        public int? TableCodeId { get; set; }
        
        [MaxLength(8)]
        [Column("PROGRAMID")]
        public string ProgramId { get; set; }

        [MaxLength(50)]
        [Column("PROFILENAME")]
        public string Profile { get; set; }

        [MaxLength(100)]
        [Column("LINKTITLE")]
        public string LinkTitle { get; set; }

        [Column("LINKTITLE_TID")]
        public int? LinkTitleTId { get; set; }

        [Column("LINKDESCRIPTION")]
        [MaxLength(254)]
        public string LinkDescription { get; set; }

        [Column("LINKDESCRIPTION_TID")]
        public int? LibkDescriptionTId { get; set; }

        [Column("DOCITEMID")]
        public int? DocItemId { get; set; }

        [MaxLength(254)]
        [Column("URL")]
        public string Url { get; set; }

        [Column("DATASOURCENAMENO")]
        public int? DataSourceNameId { get; set; }

        [MaxLength(128)]
        [Column("LOGAPPLICATION")]
        public string LogApplication { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastChanged { get; set; }

        public virtual Action Action { get; set; }

        public virtual CaseCategory CaseCategory { get; set; }

        [ForeignKey("CaseTypeId")]
        public virtual CaseType CaseType { get; set; }

        public virtual DataExtractModule DataExtractModule { get; set; }

        public virtual Country Country { get; set; }

        public virtual PropertyType PropertyType { get; set; }

        public virtual SubType SubType { get; set; }

        public virtual ApplicationBasis Basis { get; set; }

        public virtual Office Office { get; set; }

        public virtual TableCode TableCode { get; set; }

        public virtual ICollection<DataEntryTask> DataEntryTasks { get; set; }

        public virtual ICollection<ValidEvent> ValidEvents { get; set; }

        [NotMapped]
        public bool? IsLocalClient => LocalClientFlag == null ? (bool?) null : Convert.ToBoolean(LocalClientFlag);

        [NotMapped]
        public bool InUse => Convert.ToBoolean(RuleInUse.GetValueOrDefault());

        [NotMapped]
        public bool IsProtected
        {
            get { return UserDefinedRule.GetValueOrDefault() == 0; }
            set { UserDefinedRule = value ? 0 : 1; }
        }

        [NotMapped]
        public string BestFitScore => GetBestFit(Office) +
                                      GetCaseTypeBestFit(CaseTypeId, CaseType == null ? null : CaseType.ActualCaseTypeId) +
                                      GetBestFit(PropertyType) +
                                      GetBestFit(Country) +
                                      GetBestFit(CaseCategory) +
                                      GetBestFit(SubType) +
                                      GetBestFit(Basis) +
                                      // GetBestFit(RenewalType) +
                                      GetBestFit(LocalClientFlag) +
                                      GetDateBestFit(DateOfLaw) +
                                      (IsProtected ? "0" : "1");

        static string GetBestFit(object value)
        {
            return value == null ? "0" : "1";
        }

        static string GetCaseTypeBestFit(string caseType, string actualCaseType)
        {
            if (string.IsNullOrEmpty(caseType)) return "0";

            return caseType == actualCaseType ? "2" : "1";
        }

        static string GetDateBestFit(DateTime? value)
        {
            if (value == null) return "000000000";

            return "1" + value.Value.ToString("yyyyMMdd");
        }

        public Criteria WithUnknownToDefault()
        {
            CategoryUnknown = 0;
            CountryUnknown = 0;
            PropertyUnknown = 0;
            SubtypeUnknown = 0;
            return this;
        }
    }

    public static class CriteriaPurposeCodes
    {
        public const string EventsAndEntries = "E";
        public const string WindowControl = "W";
        public const string CaseLinks = "L";
        public const string CheckList = "C";
        public const string SanityCheck = "S";
    }

    public static class CriteriaExt
    {
        public static IQueryable<Criteria> WhereWorkflowCriteria(this IQueryable<Criteria> criteria)
        {
            return criteria.Where(_ => _.PurposeCode == CriteriaPurposeCodes.EventsAndEntries);
        }

        public static IQueryable<Criteria> WherePurposeCode(this IQueryable<Criteria> criteria, string purposeCode)
        {
            return criteria.Where(_ => _.PurposeCode == purposeCode);
        }

        public static IQueryable<Criteria> WhereUnknownToDefault(this IQueryable<Criteria> criteria)
        {
            return criteria.Where(_ => (!_.CategoryUnknown.HasValue || _.CategoryUnknown == 0) &&
                                       (!_.CountryUnknown.HasValue || _.CountryUnknown == 0) &&
                                       (!_.PropertyUnknown.HasValue || _.PropertyUnknown == 0) &&
                                       (!_.SubtypeUnknown.HasValue || _.SubtypeUnknown == 0));
        }
    }
}