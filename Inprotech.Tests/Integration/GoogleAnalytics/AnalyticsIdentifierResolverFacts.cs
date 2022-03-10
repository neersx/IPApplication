using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics
{
    public class AnalyticsIdentifierResolverFacts
    {
        public AnalyticsIdentifierResolverFacts()
        {
            SiteControlReader = Substitute.For<ISiteControlReader>();
            DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
            ConfigurationSettings = Substitute.For<IConfigurationSettings>();
            SiteControlReader.Read<int>(SiteControls.HomeNameNo).Returns(123);
            DisplayFormattedName.For(123).Returns("Client123");
            ConfigurationSettings[KnownAppSettingsKeys.AnalyticsIdentifierPrivateKey].Returns("Fg2342;>$%/dEw23");
            HostInfo = () => new HostInfo { DbIdentifier = "Server.DbName" };
        }

        [Fact]
        public async Task ReturnsIdentifier()
        {
            var f = Subject();
            var r = await f.Resolve();
            Assert.NotNull(r);
            Assert.Equal("Jt9Y8251Oaq2zX36bhGW9A%3d%3d.%2bCN737EFwjONUy1lzFG3og%3d%3d", r);

            SiteControlReader.Received(1).Read<int>(SiteControls.HomeNameNo);
            DisplayFormattedName.Received(1).For(123).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task IdentifiesDifferentDatabasesForEachClient()
        {
            var f = Subject();
            var r1 = await f.Resolve();

            HostInfo = () => new HostInfo { DbIdentifier = "Server.DbName2" };
            f = Subject();
            var r2 = await f.Resolve();

            Assert.NotNull(r1);
            Assert.NotNull(r2);

            Assert.Equal(r1.Split('.').First(), r2.Split('.').First());
        }

        AnalyticsIdentifierResolver Subject() => new AnalyticsIdentifierResolver(SiteControlReader, DisplayFormattedName, ConfigurationSettings, HostInfo);

        public ISiteControlReader SiteControlReader { get; }

        public IDisplayFormattedName DisplayFormattedName { get; }

        public Func<HostInfo> HostInfo { get; set; }
        public IConfigurationSettings ConfigurationSettings { get; set; }
    }
}