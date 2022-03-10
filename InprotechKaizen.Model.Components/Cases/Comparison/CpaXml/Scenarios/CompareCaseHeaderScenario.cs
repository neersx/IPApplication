using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using ComparisonModel = InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareCaseHeaderScenario : IComparisonScenarioResolver
    {
        public IEnumerable<ComparisonScenario> Resolve(CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messageDetails)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));
            if (messageDetails == null) throw new ArgumentNullException(nameof(messageDetails));

            var messages = messageDetails
                .GroupBy(_ => _.TransactionMessageCode)
                .ToDictionary(k => k.Key, v => v.Select(_ => _.TransactionMessageText));

            yield return new ComparisonScenario<ComparisonModel.CaseHeader>(
                                                            new ComparisonModel.CaseHeader
                                                            {
                                                                Id = caseDetails.SenderCaseIdentifier,
                                                                Ref = caseDetails.SenderCaseReference,
                                                                Title = caseDetails.Description("Short Title"),
                                                                Status = caseDetails.Status(),
                                                                StatusDate = caseDetails.StatusDate(),
                                                                IntClasses = caseDetails.InternationalClasses(),
                                                                LocalClasses = caseDetails.Description("Class/SubClass"),
                                                                Messages = messages,
                                                                ApplicationLanguageCode = caseDetails.CaseLanguageCode
                                                            },
                                                            ComparisonType.CaseHeader);
        }
        
        public bool IsAllowed(string source)
        {
            return true;
        }
    }

    public static class CaseDetailsExt
    {
        public static string Description(this CaseDetails caseDetails, string code)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));

            var description = caseDetails.FindAllDescriptionDetailsByCode(code).FirstOrDefault();

            if (description?.DescriptionText == null || !description.DescriptionText.Any())
            {
                return null;
            }

            return description.DescriptionText.First().Value;
        }

        static EventDetails StatusEvent(this CaseDetails caseDetails)
        {
            return caseDetails.FindAllEventDetailsByEventCode("Status").SingleOrDefault() ?? new EventDetails("Status");
        }

        public static string Status(this CaseDetails caseDetails)
        {
            var statusText = caseDetails.StatusEvent().EventText;
            return string.IsNullOrEmpty(statusText) ? caseDetails.CaseStatus : statusText;
        }

        public static DateTime? StatusDate(this CaseDetails caseDetails)
        {
            var eventDate = caseDetails.StatusEvent().EventDate;

            if (string.IsNullOrWhiteSpace(eventDate))
            {
                return null;
            }

            return DateTime.ParseExact(eventDate, "yyyy-MM-dd", CultureInfo.InvariantCulture);
        }

        public static string InternationalClasses(this CaseDetails caseDetails)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));

            var allNiceClasses = (caseDetails.GoodsServicesDetails ?? Enumerable.Empty<GoodsServicesDetails>())
                .Where(_ => _.ClassificationTypeCode == "Nice")
                .Select(_ => _.ClassDescriptionDetails ?? new ClassDescriptionDetails())
                .SelectMany(_ => _.ClassDescriptions ?? new List<ClassDescription>())
                .Select(_ => _.ClassNumber)
                .Where(_ => !string.IsNullOrWhiteSpace(_))
                .Distinct()
                .ToArray();

            if (!allNiceClasses.Any())
            {
                return null;
            }

            allNiceClasses = allNiceClasses.ToDictionary(
                                                         k => k,
                                                         v => v.TrimStart('0')
                                                        )
                                           .OrderBy(v => v.Value)
                                           .Select(k => k.Key)
                                           .ToArray();

            return string.Join(",", allNiceClasses);
        }
    }
}