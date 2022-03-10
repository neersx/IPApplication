using System;

namespace Inprotech.Web.Search.Case.CaseSearch.DueDate
{
    public class DueDateData
    {
        public bool? Event { get; set; }
        public bool? Adhoc { get; set; }
        public bool? SearchByRemindDate { get; set; }
        public bool? IsRange { get; set; }
        public bool? IsPeriod { get; set; }
        public int? RangeType { get; set; }
        public bool? SearchByDate { get; set; }
        public string DueDatesOperator { get; set; }
        public string PeriodType { get; set; }
        public int? FromPeriod { get; set; }
        public int? ToPeriod { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string ImportanceLevelOperator { get; set; }
        public string ImportanceLevelFrom { get; set; }
        public string ImportanceLevelTo { get; set; }
        public string EventOperator { get; set; }
        public dynamic EventValue { get; set; }
        public string EventCategoryOperator { get; set; }
        public dynamic EventCategoryValue { get; set; }
        public string ActionOperator { get; set; }
        public dynamic ActionValue { get; set; }
        public bool? IsRenevals { get; set; }
        public bool? IsNonRenevals { get; set; }
        public bool? IsClosedActions { get; set; }
        public bool? IsAnyName { get; set; }
        public bool? IsStaff { get; set; }
        public bool? IsSignatory { get; set; }
        public string NameTypeOperator { get; set; }
        public dynamic NameTypeValue { get; set; }
        public string NameOperator { get; set; }
        public dynamic NameValue { get; set; }
        public string NameGroupOperator { get; set; }
        public dynamic NameGroupValue { get; set; }
        public string StaffClassificationOperator { get; set; }
        public dynamic StaffClassificationValue { get; set; }

    }
}
