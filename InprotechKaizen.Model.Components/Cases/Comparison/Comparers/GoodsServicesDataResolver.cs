using System.Collections.Generic;
using Autofac.Features.Indexed;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public interface IGoodsServicesDataResolverSelector
    {
        IEnumerable<Results.GoodsServices> Resolve(string source, IEnumerable<CaseText> goodsServices,
                                      IEnumerable<ComparisonScenario<Models.GoodsServices>> comparisonScenarios,
                                      int? caseId = null,
                                      string defaultLanguage = null);
    }

    public interface IGoodsServicesDataResolver
    {
        IEnumerable<Results.GoodsServices> Resolve(IEnumerable<CaseText> goodsServices,
                                                   IEnumerable<ComparisonScenario<Models.GoodsServices>> comparisonScenarios,
                                                   int? caseId = null,
                                                   string defaultLanguage = null);
    }

    public class GoodServicesDataResolverSelector : IGoodsServicesDataResolverSelector
    {
        readonly IIndex<string, IGoodsServicesDataResolver> _goodsServicesResolvers;
        readonly IGoodsServicesDataResolver _defaultResolver;

        public GoodServicesDataResolverSelector(IIndex<string, IGoodsServicesDataResolver> goodsServicesResolvers, IGoodsServicesDataResolver defaultResolver)
        {
            _goodsServicesResolvers = goodsServicesResolvers;
            _defaultResolver = defaultResolver;
        }

        public IEnumerable<Results.GoodsServices> Resolve(string source, IEnumerable<CaseText> goodsServices,
                                                          IEnumerable<ComparisonScenario<Models.GoodsServices>> comparisonScenarios,
                                                          int? caseId = null,
                                                          string defaultLanguage = null)
        {
            return _goodsServicesResolvers.TryGetValue(source, out IGoodsServicesDataResolver specific)
                ? specific.Resolve(goodsServices, comparisonScenarios, null, defaultLanguage)
                : _defaultResolver.Resolve(goodsServices, comparisonScenarios, caseId);
        }
    }
}