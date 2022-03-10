using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareMatchingNumberEventScenario : IComparisonScenarioResolver
    {
        public IEnumerable<ComparisonScenario> Resolve(CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messageDetails)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));
            if (messageDetails == null) throw new ArgumentNullException(nameof(messageDetails));

            var numbers = (caseDetails.IdentifierNumberDetails ?? new List<IdentifierNumberDetails>())
                .Select(number => number.IdentifierNumberCode)
                .Distinct();

            var events = caseDetails.EventDetails ?? new List<EventDetails>();

            return from number in numbers
                   join @event in events on number equals @event.EventCode into e1
                   from @event in e1.DefaultIfEmpty()
                   select new ComparisonScenario<MatchingNumberEvent>(
                                                                      new MatchingNumberEvent
                                                                      {
                                                                          EventCode = @event?.EventCode ?? number,
                                                                          EventDate = @event?.EventDate.Iso8601OrNull(),
                                                                          EventDescription = @event?.EventDescription
                                                                      }, ComparisonType.MatchingNumberEvents);
        }
        
        public bool IsAllowed(string source)
        {
            return true;
        }
    }
}