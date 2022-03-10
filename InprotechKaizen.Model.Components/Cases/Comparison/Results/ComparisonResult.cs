using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    public class ComparisonResult
    {
        public ComparisonResult(string sourceSystem)
        {
            SourceSystem = sourceSystem;
        }

        public string SourceSystem { get; set; }

        public IEnumerable<ComparisonError> Errors { get; set; }

        public bool Updateable { get; set; }

        public bool Rejectable { get; set; }

        public bool RejectionResetable { get; set; }
        
        public bool HasDuplicates { get; set; }

        public Case Case { get; set; }

        public CaseImage CaseImage { get; set; }

        public IEnumerable<CaseName> CaseNames { get; set; }

        public IEnumerable<OfficialNumber> OfficialNumbers { get; set; }

        public IEnumerable<Event> Events { get; set; }

        public IEnumerable<GoodsServices> GoodsServices { get; set; }

        public IEnumerable<RelatedCase> ParentRelatedCases { get; set; } 
    }
}
