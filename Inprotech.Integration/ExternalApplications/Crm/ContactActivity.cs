using System;

namespace Inprotech.Integration.ExternalApplications.Crm
{
    public class ContactActivity
    {
        public int? ActivityType { get; set; }

        public bool IsOutgoing { get; set; }

        public int? StaffId { get; set; }

        public int? CallerId { get; set; }

        public int? RegardingId { get; set; }

        public int? CaseId { get; set; }

        public string GeneralReference { get; set; }

        public int? ActivityCategory { get; set; }

        public int? ReferredToId { get; set; }

        public bool Incomplete { get; set; }

        public string Notes { get; set; }

        public string Summary { get; set; }

        public DateTime? Date { get; set; }

        public short? CallStatus { get; set; }

        public string ClientReference { get; set; }
    }
}
