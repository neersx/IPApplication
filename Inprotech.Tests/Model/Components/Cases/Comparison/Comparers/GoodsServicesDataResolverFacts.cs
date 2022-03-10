using System.Collections.Generic;
using Autofac.Features.Indexed;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class GoodsServicesDataResolverFacts
    {
        readonly IGoodsServicesDataResolver _default = Substitute.For<IGoodsServicesDataResolver>();

        readonly IGoodsServicesDataResolver _specific = Substitute.For<IGoodsServicesDataResolver>();

        readonly IIndex<string, IGoodsServicesDataResolver> _factory = Substitute.For<IIndex<string, IGoodsServicesDataResolver>>();

        [Fact]
        public void ShouldReturnDefaultIfSpecificVersionNotFound()
        {
            var specificKey = Fixture.String();

            _factory.TryGetValue(specificKey, out _)
                    .Returns(x =>
                    {
                        x[1] = null;
                        return false;
                    });

            var subject = new GoodServicesDataResolverSelector(_factory, _default);

            IEnumerable<CaseText> caseTexts = new List<CaseText>();
            IEnumerable<ComparisonScenario<GoodsServices>> comparisonScenarios = new List<ComparisonScenario<GoodsServices>>();

            subject.Resolve(specificKey, caseTexts, comparisonScenarios);

            _default.Received(1).Resolve(caseTexts, comparisonScenarios);
            _specific.DidNotReceive().Resolve(caseTexts, comparisonScenarios);
        }

        [Fact]
        public void ShouldReturnSpecificIfFound()
        {
            var specificKey = Fixture.String();

            _factory.TryGetValue(specificKey, out _)
                    .Returns(x =>
                    {
                        x[1] = _specific;
                        return true;
                    });
            IEnumerable<CaseText> caseTexts = new List<CaseText>();
            IEnumerable<ComparisonScenario<GoodsServices>> comparisonScenarios = new List<ComparisonScenario<GoodsServices>>();

            var subject = new GoodServicesDataResolverSelector(_factory, _default);

            subject.Resolve(specificKey, caseTexts, comparisonScenarios);

            _specific.Received(1).Resolve(caseTexts, comparisonScenarios);
            _default.DidNotReceive().Resolve(caseTexts, comparisonScenarios);
        }
    }
}