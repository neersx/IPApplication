using System.Collections.Generic;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class StatusSelection
    {
        public bool IsPending { get; set; }

        public bool IsRegistered { get; set; }

        public bool IsDead { get; set; }

        public KeyValuePair<int, string>[] CaseStatuses { get; set; }

        public KeyValuePair<int, string>[] RenewalStatuses { get; set; }
    }
}
