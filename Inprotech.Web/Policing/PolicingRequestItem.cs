using System;

namespace Inprotech.Web.Policing
{
    public class PolicingRequestItem
    {
        public PolicingRequestItem()
        {
            Options = new Flags();
            Attributes = new CaseAttributes();
        }

        public int? RequestId { get; set; }
        public string Title { get; set; }
        public string Notes { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public DateTime? DateLetters { get; set; }
        public bool DueDateOnly { get; set; }
        public short? ForDays { get; set; }

        public Flags Options { get; set; }

        public class Flags
        {
            public bool Reminders { get; set; }
            public bool EmailReminders { get; set; }
            public bool Documents { get; set; }
            public bool Update { get; set; }
            public bool AdhocReminders { get; set; }
            public bool RecalculateCriteria { get; set; }
            public bool RecalculateDueDates { get; set; }
            public bool RecalculateReminderDates { get; set; }
            public bool RecalculateEventDates { get; set; }
        }
        public CaseAttributes Attributes { get; set; }
    }
}