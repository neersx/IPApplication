using System;
using System.Collections.Generic;
using Inprotech.Contracts.Messages;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class PostTimeArgs : Message
    {
        public int UserIdentityId { get; set; }
        public string Culture { get; set; }
        public int? EntityKey { get; set; }
        public IEnumerable<DateTime> SelectedDates { get; set; }
        public IEnumerable<int> SelectedEntryNos { get; set; }
        public int? StaffNameNo { get; set; }
        public string ErrorMessage { get; set; }
        public List<PostableDate> SelectedStaffDates { get; set; }
        public bool PostForAllStaff { get; set; }
    }
}
