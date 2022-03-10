using System;

namespace InprotechKaizen.Model.Components.Cases.Rules.Visualisation
{
    public class RelatedEventDetails
    {
        public int? RelatedEvent { get; set; }
        public string RelatedEventDesc { get; set; }
        public bool? UpdateEvent { get; set; }
        public bool? SatisfyEvent { get; set; }
        public bool? ClearEvent { get; set; }
        public bool? ClearDue { get; set; }
        public bool? ClearEventOnDueChange { get; set; }
        public bool? ClearDueOnDueChange { get; set; }
        public int? RelativeCycle { get; set; }
        public string Adjustment { get; set; }
        public int? CaseId { get; set; }
        public DateTime? RelatedEventDate { get; set; }
        public short? RelatedEventCycle { get; set; }
    }
}
