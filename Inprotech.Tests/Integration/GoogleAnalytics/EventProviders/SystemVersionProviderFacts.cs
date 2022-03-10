using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class SystemVersionProviderFacts
    {
        public SystemVersionProviderFacts()
        {
            SiteControlReader = Substitute.For<ISiteControlReader>();
        }

        [Fact]
        public async Task DoesNotReturnEmptySiteControls()
        {
            var f = Subject();
            var appsVersion = Fixture.String();
            SetupValues(appsVersion: appsVersion);
            var r = (await f.Provide(Fixture.Today())).ToArray();
            Assert.Equal(1, r.Length);
            Assert.Equal(AnalyticsEventCategories.VersionInprotechWebApps, r.First().Name);
            Assert.Equal(appsVersion, r.First().Value);
        }

        [Fact]
        public async Task ReturnCorrectValues()
        {
            var f = Subject();
            var appsVersion = Fixture.String();
            var dbReleaseVersion = Fixture.String();
            var integrationVersion = Fixture.String();

            SetupValues(dbReleaseVersion, appsVersion, integrationVersion);
            var r = (await f.Provide(Fixture.Today())).ToArray();
            Assert.Equal(3, r.Length);
            Assert.Equal(dbReleaseVersion, r.Single(_ => _.Name == AnalyticsEventCategories.VersionDbRelease).Value);
            Assert.Equal(appsVersion, r.Single(_ => _.Name == AnalyticsEventCategories.VersionInprotechWebApps).Value);
            Assert.Equal(integrationVersion, r.Single(_ => _.Name == AnalyticsEventCategories.VersionIntegration).Value);
        }

        SystemVersionProvider Subject() => new SystemVersionProvider(SiteControlReader);

        void SetupValues(string dbReleaseVersion = null, string appsVersion = null, string integrationVersion = null)
        {
            SiteControlReader.ReadMany<string>().ReturnsForAnyArgs(new Dictionary<string, string>()
            {
                {SiteControls.DBReleaseVersion, dbReleaseVersion},
                {SiteControls.InprotechWebAppsVersion, appsVersion},
                {SiteControls.IntegrationVersion, integrationVersion}
            });
        }

        ISiteControlReader SiteControlReader { get; }
    }
}