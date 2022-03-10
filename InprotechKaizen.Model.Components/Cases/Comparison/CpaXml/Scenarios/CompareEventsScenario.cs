using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareEventsScenario : IComparisonScenarioResolver
    {
        public IEnumerable<ComparisonScenario> Resolve(CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messageDetails)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));
            if (messageDetails == null) throw new ArgumentNullException(nameof(messageDetails));

            return (caseDetails.EventDetails ?? new List<EventDetails>())
                .Select(@event =>
                            new ComparisonScenario<Event>(
                                                          new Event
                                                              {
                                                                  EventCode = @event.EventCode,
                                                                  EventDate = @event.EventDate.Iso8601OrNull(),
                                                                  EventDescription = @event.EventDescription,
                                                                  EventText = @event.EventText
                                                              }
                                                              .WithoutUninformativeEventText(), ComparisonType.Events));
        }
        
        public bool IsAllowed(string source)
        {
            return true;
        }
    }

    public static class EventExt
    {
        static readonly string[] DiscardStrings =
        {
            "File Content History",
            "National prosecution history entry"
        };

        public static Event WithoutUninformativeEventText(this Event @event)
        {
            if (@event == null) throw new ArgumentNullException(nameof(@event));

            // USPTO Private PAIR Event Text is always 'File Content History', 
            // USPTO TSDR Event Text is always 'National prosecution history entry'
            // they are both not required in the comparison scenario 

            if (string.IsNullOrWhiteSpace(@event.EventText))
            {
                return @event;
            }

            if (DiscardStrings.Contains(@event.EventText))
            {
                @event.EventText = null;
            }

            return @event;
        }
    }
}