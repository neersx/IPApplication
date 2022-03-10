using System;
using System.Collections.Generic;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareTypeOfMarkScenerio : IComparisonScenarioResolver
    {
        public IEnumerable<ComparisonScenario> Resolve(CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messageDetails)
        {
            if (caseDetails == null) throw new ArgumentNullException(nameof(caseDetails));
            if (messageDetails == null) throw new ArgumentNullException(nameof(messageDetails));

            if (string.IsNullOrEmpty(caseDetails.TypeOfMark))
            {
                yield break;
            }

            yield return new ComparisonScenario<TypeOfMark>(new TypeOfMark
            {
                Description = caseDetails.TypeOfMark
            }, ComparisonType.TypeOfMark);
        }

        public bool IsAllowed(string source)
        {
            return true;
        }
    }
}
