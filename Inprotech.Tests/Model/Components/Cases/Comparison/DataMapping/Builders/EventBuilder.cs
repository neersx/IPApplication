using System;
using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class EventBuilder : IBuilder<Event>
    {
        public int? EventId { get; set; }
        public DateTime? EventDate { get; set; }
        public string EventCode { get; set; }
        public string EventDescription { get; set; }

        public Event Build()
        {
            return new Event
            {
                Id = EventId,
                EventDescription = EventDescription ?? Fixture.String(),
                EventCode = EventCode ?? Fixture.String(),
                EventDate = EventDate ?? Fixture.Today()
            };
        }
    }
}