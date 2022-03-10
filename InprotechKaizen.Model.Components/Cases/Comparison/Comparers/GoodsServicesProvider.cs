using System.Collections.Generic;
using System.Linq;
using Autofac.Features.Indexed;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public interface IGoodsServicesProviderSelector
    {
        IEnumerable<CaseText> Retrieve(string source, Case @case);
    }

    public interface IGoodsServicesProvider
    {
        IEnumerable<CaseText> Retrieve(Case @case);
    }

    public class GoodServicesProviderSelector : IGoodsServicesProviderSelector
    {
        readonly IIndex<string, IGoodsServicesProvider> _goodsServicesProviders;
        readonly IGoodsServicesProvider _defaultProvider;

        public GoodServicesProviderSelector(IIndex<string, IGoodsServicesProvider> goodsServicesProviders, IGoodsServicesProvider defaultProvider)
        {
            _goodsServicesProviders = goodsServicesProviders;
            _defaultProvider = defaultProvider;
        }

        public IEnumerable<CaseText> Retrieve(string source, Case @case)
        {
            if (_goodsServicesProviders.TryGetValue(source, out IGoodsServicesProvider specific))
            {
                return specific.Retrieve(@case);
            }

            return _defaultProvider.Retrieve(@case);
        }
    }

    public class DefaultGoodsServicesProvider : IGoodsServicesProvider
    {
        public IEnumerable<CaseText> Retrieve(Case @case)
        {
            var goodsAndServices = @case.GoodsAndServices()
                                        .GroupBy(t => t.Class)
                                        .Select(g => g.OrderBy(_ => _.Language).ThenByDescending(t => t.Number).First())
                                        .ToArray();

            foreach (var g in goodsAndServices.Where(g => g.Language != null))
            {
                g.ShortText = string.Empty;
                g.LongText = string.Empty;
            }

            return goodsAndServices;
        }
    }

    public class InnographyGoodsServicesProvider : IGoodsServicesProvider
    {
        public IEnumerable<CaseText> Retrieve(Case @case)
        {
            var goodsAndServices = @case.GoodsAndServices()
                                        .GroupBy(t => new {t.Class, t.Language})
                                        .Select(g => g.OrderByDescending(_ => _.Number).First())
                                        .ToArray();

            return goodsAndServices;
        }
    }
}