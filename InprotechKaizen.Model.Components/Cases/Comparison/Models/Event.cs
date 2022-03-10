using System;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Models
{
    [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Event")]
    public class Event : IEvent
    {
        public int? Id { get; set; }

        public string EventCode { get; set; }

        public DateTime? EventDate { get; set; }

        public string EventDescription { get; set; }

        public string EventText { get; set; }

        public string CorrelationRef { get; set; }
    }
}