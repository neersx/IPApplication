using System.Collections.Generic;

namespace Inprotech.Web.Cases.EventRules.Models
{
    public class EventUpdateInfo
    {
        public bool UpdateImmediatelyInfo { get; set; }
        public bool UpdateWhenDueInfo { get; set; }
        public string Status { get; set; }
        public string FeesAndChargesInfo { get; set; }
        public string FeesAndChargesInfo2 { get; set; }
        public string CreateAction { get; set; }
        public string CloseAction { get; set; }
        public string ReportToCpaInfo { get; set; }
        public IEnumerable<UpdateEventDateItem> DatesToUpdate { get; set; }
        public IEnumerable<string> DatesToClear { get; set; }
    }

    public class UpdateEventDateItem
    {
        public string FormattedDescription { get; set; }

        public string Adjustment { get; set; }
    }
}
