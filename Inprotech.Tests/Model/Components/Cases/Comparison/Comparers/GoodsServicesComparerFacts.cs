using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using CaseHeader = InprotechKaizen.Model.Components.Cases.Comparison.Models.CaseHeader;
using GoodsServices = InprotechKaizen.Model.Components.Cases.Comparison.Models.GoodsServices;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class GoodsServicesComparerFacts
    {
        public class CompareMethod : FactBase
        {
            IGoodsServicesProviderSelector GoodsServicesProvider { get; set; }

            IGoodsServicesDataResolverSelector GoodsServicesDataResolver { get; set; }

            readonly GoodsServicesComparisonScenarioBuilder _scenarioBuilder =
                new GoodsServicesComparisonScenarioBuilder();

            readonly CaseHeaderComparisonScenarioBuilder _caseHeaderScenarioBuilder =
                new CaseHeaderComparisonScenarioBuilder();

            public GoodsServicesComparer Subject()
            {
                GoodsServicesProvider = Substitute.For<IGoodsServicesProviderSelector>();
                GoodsServicesDataResolver = Substitute.For<IGoodsServicesDataResolverSelector>();
                return new GoodsServicesComparer(GoodsServicesProvider, GoodsServicesDataResolver);
            }

            [Fact]
            public void ShouldCallRetrieveAndResolveMethod()
            {
                var subject = Subject();
                var inprotechCase = new InprotechCaseBuilder(Db).Build();

                GoodsServicesProvider.Retrieve(Arg.Any<string>(), inprotechCase)
                 .Returns(x => Build((Case) x[1]));

                _scenarioBuilder.GoodsServices = new GoodsServices()
                {
                    Class = Constants.Class9,
                    Text = Constants.ShortText
                };
                _caseHeaderScenarioBuilder.CaseHeader = new CaseHeader();

                var source = Fixture.String();

                var result = new ComparisonResult(source);

                subject.Compare(inprotechCase, new ComparisonScenario[] {_scenarioBuilder.Build(), _caseHeaderScenarioBuilder.Build()}, result);

                GoodsServicesProvider.Received(1).Retrieve(source, inprotechCase);
                GoodsServicesDataResolver.Received(1).Resolve(source, Arg.Any<IEnumerable<CaseText>>(), Arg.Any<IEnumerable<ComparisonScenario<GoodsServices>>>(), Arg.Any<int>());
            }

            [Fact]
            public void ShouldNotCallResolveMethod()
            {
                var subject = Subject();

                var inprotechCase = new InprotechCaseBuilder(Db).Build();

                GoodsServicesProvider.Retrieve(Arg.Any<string>(), inprotechCase)
                 .Returns(x => Build((Case) x[1]));

                _scenarioBuilder.GoodsServices = new GoodsServices();
                _caseHeaderScenarioBuilder.CaseHeader = new CaseHeader();

                var source = Fixture.String();

                var result = new ComparisonResult(source);

                subject.Compare(inprotechCase, new ComparisonScenario[] {_caseHeaderScenarioBuilder.Build()}, result);

                GoodsServicesProvider.Received(1).Retrieve(source, inprotechCase);
                GoodsServicesDataResolver.Received(0).Resolve(Arg.Any<string>(), Arg.Any<IEnumerable<CaseText>>(), Arg.Any<IEnumerable<ComparisonScenario<GoodsServices>>>());
            }
            static IEnumerable<CaseText> Build(Case @case)
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
    }
}