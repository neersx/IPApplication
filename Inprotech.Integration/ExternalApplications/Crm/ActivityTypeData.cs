
using System;

namespace Inprotech.Integration.ExternalApplications.Crm
{
    [Serializable]
    public class ActivityTypeData
    {
        public int ActivityTypeId { get; set; }
        public string ActivityTypeDescription { get; set; }
        public bool IsOutgoing { get; set; }
    }
}
