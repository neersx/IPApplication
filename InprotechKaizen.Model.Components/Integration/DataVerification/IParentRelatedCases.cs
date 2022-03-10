using System;
using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Integration.DataVerification
{
    public interface IParentRelatedCases
    {
        IEnumerable<ParentRelatedCase> Resolve(int[] caseIds, string[] relationshipCodes);
    }

    public class ParentRelatedCase
    {
        public int CaseKey { get; set; }
        public string CountryCode { get; set; }
        public string Number { get; set; }
        public DateTime? Date { get; set; }
        public string Relationship { get; set; }
        public int RelationId { get; set; }
        public int? RelatedCaseId { get; set; }
        public string RelatedCaseRef { get; set; }
        public int? EventId { get; set; }
    }
}
