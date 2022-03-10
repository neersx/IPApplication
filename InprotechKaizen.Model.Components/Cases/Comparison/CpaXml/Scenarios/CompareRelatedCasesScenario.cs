using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Ede;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareRelatedCasesScenario : IComparisonScenarioResolver
    {
        public IEnumerable<ComparisonScenario> Resolve(CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messageDetails)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));
            if (messageDetails == null) throw new ArgumentNullException(nameof(messageDetails));

            return (caseDetails.AssociatedCaseDetails ?? new List<AssociatedCaseDetails>())
                .Select(acd =>
                            new ComparisonScenario<RelatedCase>(From(acd), ComparisonType.RelatedCases));
        }

        public bool IsAllowed(string source)
        {
            return source != "IpOneData";
        }

        static RelatedCase From(AssociatedCaseDetails associatedCaseDetails)
        {
            var code = associatedCaseDetails.AssociatedCaseRelationshipCode;
            var eventCode = associatedCaseDetails.FirstEventCode() ?? code;

            return new RelatedCase
                   {
                       CountryCode = associatedCaseDetails.AssociatedCaseCountryCode,
                       Description = associatedCaseDetails.AssociatedCaseComment ?? code,
                       EventDate = associatedCaseDetails.EventDate(eventCode),
                       OfficialNumber = associatedCaseDetails.OfficialNumber(),
                       Status = associatedCaseDetails.AssociatedCaseStatus,
                       RegistrationNumber = associatedCaseDetails.OfficialNumber(NumberTypes.RegistrationOrGrant)
                   };
        }
    }

    public static class AssociatedCaseDetailsExt
    {
        public static string FirstEventCode(this AssociatedCaseDetails associatedCaseDetails)
        {
            if (associatedCaseDetails == null) throw new ArgumentNullException(nameof(associatedCaseDetails));

            var eventDetails = (associatedCaseDetails.AssociatedCaseEventDetails ?? new List<EventDetails>())
                .FirstOrDefault();

            return eventDetails?.EventCode;
        }

        public static DateTime? EventDate(this AssociatedCaseDetails associatedCaseDetails, string code)
        {
            if (associatedCaseDetails == null) throw new ArgumentNullException(nameof(associatedCaseDetails));

            var eventDetails = (associatedCaseDetails.AssociatedCaseEventDetails ?? new List<EventDetails>())
                .FirstOrDefault(_ => _.EventCode == code);

            if (string.IsNullOrWhiteSpace(eventDetails?.EventDate))
            {
                return null;
            }

            return DateTime.ParseExact(eventDetails.EventDate, "yyyy-MM-dd", CultureInfo.InvariantCulture);
        }

        public static string OfficialNumber(this AssociatedCaseDetails associatedCaseDetails, string code = null)
        {
            if (associatedCaseDetails == null) throw new ArgumentNullException(nameof(associatedCaseDetails));

            var number = (associatedCaseDetails.AssociatedCaseIdentifierNumberDetails ?? new List<IdentifierNumberDetails>())
                .FirstOrDefault(_ => code != null ? _.IdentifierNumberCode == code : _.IdentifierNumberCode != NumberTypes.RegistrationOrGrant);

            return number?.IdentifierNumberText;
        }
    }
}