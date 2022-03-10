using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using Case = InprotechKaizen.Model.Cases.Case;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class GoodsServicesComparer : ISpecificComparer
    {
        readonly IGoodsServicesProviderSelector _goodsServicesProvider;
        readonly IGoodsServicesDataResolverSelector _goodsServicesDataResolver;

        [SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "PlainText")]
        public GoodsServicesComparer(IGoodsServicesProviderSelector goodsServicesProvider,
                                     IGoodsServicesDataResolverSelector goodsServicesDataResolver)
        {
            _goodsServicesProvider = goodsServicesProvider;
            _goodsServicesDataResolver = goodsServicesDataResolver;
        }

        public void Compare(Case @case, IEnumerable<ComparisonScenario> comparisonScenarios, ComparisonResult result)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (comparisonScenarios == null) throw new ArgumentNullException(nameof(comparisonScenarios));
            if (result == null) throw new ArgumentNullException(nameof(result));

            var comparisonScenariosList = comparisonScenarios.ToList();
            var scenarios = comparisonScenariosList.OfType<ComparisonScenario<Models.GoodsServices>>().ToArray();

            // Goods Services retrieval method is different between source
            // therefore the same algorithm used for each source must implement the same logic for comparison and update.
            var goodsAndServices = _goodsServicesProvider.Retrieve(result.SourceSystem, @case).ToArray();

            if (!scenarios.Any() && !goodsAndServices.Any())
            {
                return;
            }

            var caseHeaderComparisonScenarios = comparisonScenariosList.OfType<ComparisonScenario<Models.CaseHeader>>().ToArray();
            var caseHeader = caseHeaderComparisonScenarios.Select(_ => _.Mapped).ToList().First();

            result.GoodsServices = _goodsServicesDataResolver.Resolve(result.SourceSystem,
                                                                  goodsAndServices,
                                                                  scenarios,
                                                                  @case.Id,
                                                                  caseHeader.ApplicationLanguageCode);
        }
    }
}