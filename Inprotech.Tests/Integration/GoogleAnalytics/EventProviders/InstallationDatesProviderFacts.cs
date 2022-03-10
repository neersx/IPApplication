using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Configuration.SiteControl;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class InstallationDatesProviderFacts : FactBase
    {
        [Fact]
        public async Task DoesNotReturnEmptySiteControls()
        {
            var f = Subject();
            var appsVersion = Fixture.Today();
            SetupSiteControl(SiteControls.DBReleaseVersion, null);
            SetupSiteControl(SiteControls.InprotechWebAppsVersion, appsVersion);

            var r = (await f.Provide(Fixture.Today())).ToArray();
            Assert.Equal(1, r.Length);
            Assert.Equal(AnalyticsEventCategories.InstallationDateInprotechWebApps, r.First().Name);
            Assert.Equal(Format(appsVersion), r.First().Value);
        }

        [Fact]
        public async Task ReturnCorrectValues()
        {
            var f = Subject();
            var appsVersion = Fixture.Today();
            var dbReleaseVersion = Fixture.PastDate();
            var integrationVersion = Fixture.FutureDate();

            SetupSiteControl(SiteControls.InprotechWebAppsVersion, appsVersion);
            SetupSiteControl(SiteControls.DBReleaseVersion, dbReleaseVersion);
            SetupSiteControl(SiteControls.IntegrationVersion, integrationVersion);

            var r = (await f.Provide(Fixture.Today())).ToArray();
            Assert.Equal(3, r.Length);
            Assert.Equal(Format(dbReleaseVersion), r.Single(_ => _.Name == AnalyticsEventCategories.InstallationDateDbRelease).Value);
            Assert.Equal(Format(appsVersion), r.Single(_ => _.Name == AnalyticsEventCategories.InstallationDateInprotechWebApps).Value);
            Assert.Equal(Format(integrationVersion), r.Single(_ => _.Name == AnalyticsEventCategories.InstallationDateIntegration).Value);
        }

        InstallationDatesProvider Subject() => new InstallationDatesProvider(Db);

        string Format(DateTime dt) => dt.ToString("yyyy-MM-dd");

        void SetupSiteControl(string siteControl, DateTime? lastChanged)
        {
            new SiteControl(siteControl) { LastChanged = lastChanged }.In(Db);
        }
    }
}