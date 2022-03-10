using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    public class CriteriaRows
    {
        public int CriteriaNo { get; set; }
        public string PurposeCode { get; set; }
        public string CaseType { get; set; }
        public string Action { get; set; }
        public short? ChecklistType { get; set; }
        public string ProgramId { get; set; }
        public string PropertyType { get; set; }
        public decimal? PropertyUnknown { get; set; }
        public string CountryCode { get; set; }
        public decimal? CountryUnknown { get; set; }
        public string CaseCategory { get; set; }
        public decimal? CategoryUnknown { get; set; }
        public string SubType { get; set; }
        public decimal? SubTypeUnknown { get; set; }

        public string Basis { get; set; }

        //public string RegisteredUsers { get; set; }
        //public string LocalClientFlag { get; set; }
        public string TableCode { get; set; }

        public string RateNo { get; set; }

        //public string DateOfAct { get; set; }
        //public string UserDefinedRule { get; set; }
        //public string RuleInUse { get; set; }
        //public string StartDetailEntry { get; set; }
        public string ParentCriteria { get; set; }

        //public string BelongsToGroup { get; set; }
        public string Description { get; set; }

        //public string TypeOfMark { get; set; }
        public string RenewalType { get; set; }

        //[Column("DESCRIPTION_TID")]
        //public string DESCRIPTION_TID { get; set; }
        // public string CaseOfficeId { get; set; }
        public string LinkTitle { get; set; }

        [Column("LINKTITLE_TID")]
        public int? LinkTitle_TId { get; set; }

        public string LinkDescription { get; set; }

        [Column("LINKDESCRIPTION_TID")]
        public int? LinkDescription_TId { get; set; }

        public int? DocItemId { get; set; }
        public string Url { get; set; }
        public bool IsPublic { get; set; }

        public int? GroupId { get; set; }

        //public int? ProductCode { get; set; }
        //public string NewCaseType { get; set; }
        //public string NewCountryCode { get; set; }
        //public string NewPropertyType { get; set; }
        //public string NewCaseCategory { get; set; }
        //public string ProfileName { get; set; }
        //public string SystemId { get; set; }
        //public string DataExtractId { get; set; }
        //public string RuleType { get; set; }
        //public string RequestType { get; set; }
        //public string DataSourceType { get; set; }
        //public string DataSourceNameNo { get; set; }
        //public string RenewalStatus { get; set; }
        //public string StatusCode { get; set; }
        public string BestFit { get; set; }
        //public string ProfileId { get; set; }
        //public string CpaRenewalType { get; set; }
        //public string NewSubType { get; set; }
    }
}