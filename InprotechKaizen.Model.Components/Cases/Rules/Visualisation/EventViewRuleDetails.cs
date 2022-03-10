using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Cases.Rules.Visualisation
{
    public class EventViewRuleDetails
    {
        public int CaseId { get; set; }
        public int EventId { get; set; }
        public string Action { get; set; }
        public int Cycle { get; set; }
        public string CaseReference { get; set; }
        public EventControlDetails EventControlDetails { get; set; }
        public IEnumerable<DueDateCalculationDetails> DueDateCalculationDetails { get; set; }
        public IEnumerable<DateComparisonDetails> DateComparisonDetails { get; set; }
        public IEnumerable<RelatedEventDetails> RelatedEventDetails { get; set; }
        public IEnumerable<ReminderDetails> ReminderDetails { get; set; }
        public IEnumerable<DocumentsDetails> DocumentsDetails { get; set; }
        public IEnumerable<DatesLogicDetails> DatesLogicDetails { get; set; }
    }
}