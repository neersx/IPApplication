using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using Case = InprotechKaizen.Model.Cases.Case;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public interface ISpecificComparer
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        void Compare(Case @case, IEnumerable<ComparisonScenario> comparisonScenarios, ComparisonResult result);
    }

    public interface IEventsComparer : ISpecificComparer
    {
    }
}