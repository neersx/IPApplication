using System;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    public class RelatedCase
    {
        public int? SyncId { get; set; }

        public Value<string> RelationshipCode { get; set; }
        
        public Value<string> CountryCode { get; set; }

        public Value<string> Description { get; set; }

        public Value<string> OfficialNumber { get; set; }

        public Value<int?> EventId { get; set; }

        public Value<string> EventDescription { get; set; }

        public Value<DateTime?> PriorityDate { get; set; }

        public Value<string> ParentStatus { get; set; }

        public Value<string> RegistrationNumber { get; set; }

        public string RelatedCaseRef { get; set; }

        public int? RelatedCaseId { get; set; }
    }
}
