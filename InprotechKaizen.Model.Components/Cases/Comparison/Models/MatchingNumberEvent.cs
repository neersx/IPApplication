using System;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Models
{
    public class MatchingNumberEvent : IEvent
    {
        public int? Id { get; set; }

        public string EventCode { get; set; }

        public DateTime? EventDate { get; set; }

        public string EventDescription { get; set; }
    }
}