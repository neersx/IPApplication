namespace InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner
{
    public class CaseScreenDesignerCharacteristics : Characteristics.Characteristics
    {
        public string Basis { get; set; }
        public string CaseProgram { get; set; }
        public string Profile { get; set; }
    }

    public class SearchCriteria : CaseScreenDesignerCharacteristics
    {
        public string ApplyTo { get; set; }

        public string MatchType { get; set; }

        public bool IncludeProtectedCriteria { get; set; }

        public bool IncludeCriteriaNotInUse { get; set; }
    }

    public class CaseScreenDesignerListItem
    {
        public int Id { get; set; }
        public string CriteriaName { get; set; }
        public string ProgramId { get; set; }
        public string ProgramName { get; set; }
        public int? OfficeCode { get; set; }
        public string OfficeDescription { get; set; }
        public string CaseTypeCode { get; set; }
        public string CaseTypeDescription { get; set; }
        public string JurisdictionCode { get; set; }
        public string JurisdictionDescription { get; set; }
        public string PropertyTypeCode { get; set; }
        public string PropertyTypeDescription { get; set; }
        public string CaseCategoryCode { get; set; }
        public string CaseCategoryDescription { get; set; }
        public string SubTypeCode { get; set; }
        public string SubTypeDescription { get; set; }
        public string BasisCode { get; set; }
        public string BasisDescription { get; set; }
        public string ProfileCode { get; set; }
        public string ProfileDescription { get; set; }
        public bool IsLocalClient { get; set; }
        public bool InUse { get; set; }
        public bool IsProtected { get; set; }
        public bool IsInherited { get; set; }
        public bool IsParent { get; set; }
        public string ExaminationTypeDescription { get; set; }
        public string RenewalTypeDescription { get; set; }
        public string BestFit { get; set; }
    }
}