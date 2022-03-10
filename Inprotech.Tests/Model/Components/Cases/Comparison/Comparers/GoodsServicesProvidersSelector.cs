using Autofac.Features.Indexed;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class GoodsServicesProvidersSelector
    {
        readonly IGoodsServicesProvider _default = Substitute.For<IGoodsServicesProvider>();

        readonly IGoodsServicesProvider _specific = Substitute.For<IGoodsServicesProvider>();

        readonly IIndex<string, IGoodsServicesProvider> _factory = Substitute.For<IIndex<string, IGoodsServicesProvider>>();

        static Case CreateCase()
        {
            var @case = new CaseBuilder().Build();

            @case.CaseTexts.Add(new CaseText(@case.Id, "G", 0, "01"));

            return @case;
        }

        [Fact]
        public void ShouldReturnDefaulfIfSpecificVersionNotFound()
        {
            var specificKey = Fixture.String();

            IGoodsServicesProvider specific;
            _factory.TryGetValue(specificKey, out specific)
                    .Returns(x =>
                    {
                        x[1] = null;
                        return false;
                    });

            var @case = CreateCase();
            var subject = new GoodServicesProviderSelector(_factory, _default);

            subject.Retrieve(specificKey, @case);

            _default.Received(1).Retrieve(@case);
            _specific.DidNotReceive().Retrieve(@case);
        }

        [Fact]
        public void ShouldReturnSpecificIfFound()
        {
            var specificKey = Fixture.String();

            IGoodsServicesProvider specific;
            _factory.TryGetValue(specificKey, out specific)
                    .Returns(x =>
                    {
                        x[1] = _specific;
                        return true;
                    });

            var @case = CreateCase();
            var subject = new GoodServicesProviderSelector(_factory, _default);

            subject.Retrieve(specificKey, @case);

            _specific.Received(1).Retrieve(@case);
            _default.DidNotReceive().Retrieve(@case);
        }
    }
}