using System;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class TimeSearchParams
    {
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public int StaffId { get; set; }
        public bool IsPosted { get; set; }
        public bool IsUnposted { get; set; }
        public bool IsPostedOnly => IsPosted && !IsUnposted;
        public bool IsUnpostedOnly => !IsPosted && IsUnposted;
        public int? Entity { get; set; }
        public int?[] CaseIds { get; set; }
        public string ActivityId { get; set; }
        public int? NameId { get; set; }
        public bool AsInstructor { get; set; }
        public bool AsDebtor { get; set; }
        public string NarrativeSearch { get; set; }
    }
}
