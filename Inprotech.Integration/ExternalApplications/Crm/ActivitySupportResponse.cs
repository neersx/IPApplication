
using System;
using System.Collections.Generic;

namespace Inprotech.Integration.ExternalApplications.Crm
{
    [Serializable]
    public class ActivitySupportResponse
    {
        public List<ActivityCategory> ActivityCategories { get; set; }

        public List<ActivityTypeData> ActivityTypes { get; set; }

        public List<CallStatusType> CallStatus { get; set; }

    }
}
