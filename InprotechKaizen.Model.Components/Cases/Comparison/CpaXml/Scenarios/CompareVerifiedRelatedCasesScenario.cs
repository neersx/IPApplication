using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareVerifiedRelatedCasesScenario : IComparisonScenarioResolver
    {
        public IEnumerable<ComparisonScenario> Resolve(CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messageDetails)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));
            if (messageDetails == null) throw new ArgumentNullException(nameof(messageDetails));

            return from acd in caseDetails.AssociatedCaseDetails ?? new List<AssociatedCaseDetails>()
                   let relationshipCode = acd.AssociatedCaseRelationshipCode.Replace("[DV]", string.Empty)
                   group acd by relationshipCode
                   into acd1
                   orderby acd1.Key
                   let input = acd1.FirstOrDefault(_ => _.AssociatedCaseRelationshipCode.StartsWith("[DV]"))
                   let source = acd1.Except(new[] {input}).Single()
                   select new ComparisonScenario<VerifiedRelatedCase>(From(source, input), ComparisonType.VerifiedRelatedCases);
        }

        public bool IsAllowed(string source)
        {
            return source == "Innography";
        }

        static VerifiedRelatedCase From(AssociatedCaseDetails associatedCaseDetails, AssociatedCaseDetails input)
        {
            var code = associatedCaseDetails.AssociatedCaseRelationshipCode;
            var eventCode = associatedCaseDetails.FirstEventCode();
            var inputEventCode = input?.FirstEventCode();

            var status = input?.AssociatedCaseComment == null
                ? new Dictionary<string, string>()
                : (from s in input.AssociatedCaseComment.Split(';')
                   let k = s.Split(':')
                   select new
                   {
                       key = k.First(),
                       value = k.Last()
                   })
                .ToDictionary(k => k.key, v => v.value);

            return new VerifiedRelatedCase
            {
                CountryCode = associatedCaseDetails.AssociatedCaseCountryCode,
                Description = associatedCaseDetails.AssociatedCaseComment ?? code,
                EventDate = associatedCaseDetails.EventDate(eventCode),
                OfficialNumber = associatedCaseDetails.OfficialNumber(),
                InputCountryCode = input?.AssociatedCaseCountryCode,
                InputEventDate = input?.EventDate(inputEventCode),
                InputOfficialNumber = input?.OfficialNumber(),
                CountryCodeVerified = status.Get("CountryCodeStatus") == "VERIFICATION_SUCCESS",
                EventDateVerified = status.Get("EventDateStatus") == "VERIFICATION_SUCCESS",
                OfficialNumberVerified = status.Get("OfficialNumberStatus") == "VERIFICATION_SUCCESS"
            };
        }
    }
}