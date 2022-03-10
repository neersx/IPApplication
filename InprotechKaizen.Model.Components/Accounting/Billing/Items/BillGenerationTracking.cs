using System;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public class BillGenerationTracking
    {
        public Guid RequestContextId { get; set; }

        public int ContentId { get; set; }

        public string ConnectionId { get; set; }
    }

}
