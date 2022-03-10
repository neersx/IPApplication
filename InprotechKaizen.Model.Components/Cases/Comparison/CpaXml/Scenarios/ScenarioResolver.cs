using System.Collections.Generic;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public interface IComparisonScenarioResolver
    {
        IEnumerable<ComparisonScenario> Resolve(CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messageDetails);

        bool IsAllowed(string source);
    }
}
