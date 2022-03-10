using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class LawUpdateAnalyticsProviderFacts : FactBase
    {
        public LawUpdateAnalyticsProviderFacts()
        {
            SiteControlReader = Substitute.For<ISiteControlReader>();
        }

        [Fact]
        public async Task DoesNotReturnWithoutValue()
        {
            var f = Subject();
            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Empty(r);
        }

        [Fact]
        public async Task ReturnsCpaLawUpdateService()
        {
            var f = Subject();
            SiteControlReader.Read<string>(SiteControls.CPALawUpdateService).Returns("2020-19-02");

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(1, r.Length);
            Assert.Equal("2020-19-02", r.Single(_ => _.Name == AnalyticsEventCategories.LawUpdateServiceDate).Value);
        }

        [Fact]
        public async Task ReturnsDataFromValidEvent()
        {
            var f = Subject();
            new ValidEvent() {LogApplication = "Inprotech Configuration Tool V 1.5", LastChanged = Fixture.Today()}.In(Db);

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal(Fixture.Today().ToString(), r.Single(_ => _.Name == AnalyticsEventCategories.IctDate).Value);
            Assert.Equal("Inprotech Configuration Tool V 1.5", r.Single(_ => _.Name == AnalyticsEventCategories.IctVersion).Value);
        }

        [Fact]
        public async Task ChecksCriteriaEventDoesNotHaveValue()
        {
            var f = Subject();
            new Criteria() {LogApplication = "Inprotech Configuration Tool V 1.5", LastChanged = Fixture.Today()}.In(Db);

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal(Fixture.Today().ToString(), r.Single(_ => _.Name == AnalyticsEventCategories.IctDate).Value);
            Assert.Equal("Inprotech Configuration Tool V 1.5", r.Single(_ => _.Name == AnalyticsEventCategories.IctVersion).Value);
        }

        LawUpdateAnalyticsProvider Subject() => new LawUpdateAnalyticsProvider(Db, SiteControlReader);
        ISiteControlReader SiteControlReader { get; }
    }
}