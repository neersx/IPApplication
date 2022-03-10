using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using Case = InprotechKaizen.Model.Cases.Case;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class VerifiedParentRelatedCasesComparer : ISpecificComparer
    {
        readonly IRelatedCaseResultBuilder _relatedCaseResultBuilder;

        public VerifiedParentRelatedCasesComparer(IRelatedCaseResultBuilder relatedCaseResultBuilder)
        {
            _relatedCaseResultBuilder = relatedCaseResultBuilder;
        }

        public void Compare(Case @case, IEnumerable<ComparisonScenario> comparisonScenarios, ComparisonResult result)
        {
            if (result == null) throw new ArgumentNullException(nameof(result));

            var relatedCases = comparisonScenarios.OfType<ComparisonScenario<VerifiedRelatedCase>>()
                                                  .Select(_ => _.Mapped)
                                                  .ToArray();

            if (!relatedCases.Any())
            {
                return;
            }

            result.ParentRelatedCases = _relatedCaseResultBuilder.Build(@case, relatedCases);
        }
    }
}