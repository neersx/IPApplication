using System;

namespace Inprotech.Web.Cases.Maintenance.Models
{
    public class EventSaveModel
    {
        public string ActionId { get; set; }
        public int EventNo { get; set; }
        public int CriteriaId { get; set; }
        public int? Cycle { get; set; }
        public DateTime? EventDate { get; set; }
        public DateTime? EventDueDate { get; set; }
        public int? NameId { get; set; }
        public string NameTypeKey { get; set; }
    }

    public class EventTopicSaveModel
    {
        public EventSaveModel[] Rows { get; set; }
    }
}