using System;
using System.Collections.Generic;

namespace Inprotech.Web.Cases.EventRules.Models
{
    public class EventRulesModel
    {
        public class EventRulesRequest
        {
            public int CaseId { get; set; }
            public int EventNo { get; set; }
            public int Cycle { get; set; }
            public string Action { get; set; }
        }

        public class EventRulesDetailsModel
        {
            public string CaseReference { get; set; }
            public string EventDescription { get; set; }
            public string Action { get; set; }
            public string Notes { get; set; }
            public EventInformation EventInformation { get; set; }
            public DueDateCalculationInfo DueDateCalculationInfo { get; set; }
            public IEnumerable<RemindersInfo> RemindersInfo { get; set; }
            public IEnumerable<DatesLogicDetailInfo> DatesLogicInfo { get; set; }
            public IEnumerable<DocumentsInfo> DocumentsInfo { get; set; }
            public EventUpdateInfo EventUpdateInfo { get; set; }
        }

        public class EventInformation
        {
            public int EventNumber { get; set; }
            public int Cycle { get; set; }
            public DateTime? EventDate { get; set; }
            public DateTime? LastModified { get; set; }
            public int CriteriaNumber { get; set; }
            public string ByLogin { get; set; }
            public string ImportanceLevel { get; set; }
            public string From { get; set; }
            public int? MaximumCycle { get; set; }
        }

        public class DatesLogicDetailInfo
        {
            public string FormattedDescription { get; set; }
            public string TestFailureAction { get; set; }
            public string MessageDisplayed { get; set; }
            public string FailureActionType { get; set; }
        }
    }
}
