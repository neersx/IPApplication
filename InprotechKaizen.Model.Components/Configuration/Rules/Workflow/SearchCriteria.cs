namespace InprotechKaizen.Model.Components.Configuration.Rules.Workflow
{
    public class WorkflowCharacteristics : Characteristics.Characteristics
    {
        public string Basis { get; set; }
    }

    public class SearchCriteria : WorkflowCharacteristics
    {
        public string ApplyTo { get; set; }

        public string MatchType { get; set; }

        public bool? IncludeProtectedCriteria { get; set; }

        public bool? IncludeCriteriaNotInUse { get; set; }

        public int? Event { get; set; }
    }
}