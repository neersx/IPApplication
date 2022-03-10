using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareNumbersScenario : IComparisonScenarioResolver
    {
        public IEnumerable<ComparisonScenario> Resolve(CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messageDetails)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));
            if (messageDetails == null) throw new ArgumentNullException(nameof(messageDetails));

            return (caseDetails.IdentifierNumberDetails ?? new List<IdentifierNumberDetails>())
                .Select(number =>
                            new ComparisonScenario<OfficialNumber>(
                                                                   new OfficialNumber
                                                                   {
                                                                       Code = number.IdentifierNumberCode,
                                                                       NumberType = number.IdentifierNumberCode,
                                                                       Number = number.IdentifierNumberText,
                                                                       EventDate = FindMatchingEvent(caseDetails, number.IdentifierNumberCode)
                                                                   }, ComparisonType.OfficialNumbers));
        }
        
        public bool IsAllowed(string source)
        {
            return true;
        }

        static DateTime? FindMatchingEvent(CaseDetails caseDetails, string numberTypeCode)
        {
            var events = caseDetails.FindAllEventDetailsByEventCode(numberTypeCode).ToArray();
            var singleMatchingEvent = events.Length == 1 ? events[0] : null;

            if (string.IsNullOrWhiteSpace(singleMatchingEvent?.EventDate))
            {
                return null;
            }

            return DateTime.ParseExact(singleMatchingEvent.EventDate, "yyyy-MM-dd", CultureInfo.InvariantCulture);
        }
    }
}