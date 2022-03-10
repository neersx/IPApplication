using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Reports;
using InprotechKaizen.Model.Components.Integration.ReportingServices;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Reports
{
    public class ReportingServicesSettingsResolverFacts : FactBase
    {
        ReportingServicesSettingsResolver GetSubject(ReportingServicesSetting settings = null)
        {
            var cryptoService = Substitute.For<ICryptoService>();

            cryptoService.Decrypt(Arg.Any<string>()).Returns(JsonConvert.SerializeObject(settings ?? new ReportingServicesSetting()));

            return new ReportingServicesSettingsResolver(() => Db, cryptoService);
        }

        [Fact]
        public async Task ShouldAddReportingServicesSettingsIfInitiallyNotThere()
        {
            var isSaved = await GetSubject().Save(new ReportingServicesSetting());

            Assert.True(isSaved);

            Assert.Single(Db.Set<ExternalSettings>().Where(_ => _.ProviderName == "ReportingServicesSetting"));
        }

        [Fact]
        public async Task ShouldReturnInvalidGetReportingServicesSettings()
        {
            new ExternalSettingsBuilder
            {
                ProviderName = "ReportingServicesSetting",
                Settings = null
            }.Build().In(Db);

            var settings = await GetSubject().Resolve();
            Assert.False(settings.IsValid());
        }

        [Fact]
        public async Task ShouldReturnReportingServicesSettings()
        {
            new ExternalSettingsBuilder {ProviderName = "ReportingServicesSetting", Settings = Fixture.String()}.Build().In(Db);

            var settings = new ReportingServicesSetting
            {
                Timeout = Fixture.Integer(),
                MessageSize = Fixture.Integer(),
                ReportServerBaseUrl = "www.inprotech.com/reportingserver",
                RootFolder = Fixture.String(),
                Security = new SecurityElement {Password = Fixture.String(), Username = Fixture.String(), Domain = Fixture.String()}
            };

            var subject = GetSubject(settings);

            var results = await subject.Resolve();

            Assert.Equal(settings.ReportServerBaseUrl, results.ReportServerBaseUrl);
            Assert.Equal(settings.MessageSize, results.MessageSize);
            Assert.Equal(settings.RootFolder, results.RootFolder);
            Assert.Equal(settings.Security.Username, results.Security.Username);
            Assert.Equal(settings.Security.Domain, results.Security.Domain);
        }

        [Fact]
        public async Task ShouldReturnTrueUpdateReportingServicesSettings()
        {
            new ExternalSettingsBuilder {ProviderName = "ReportingServicesSetting", Settings = Fixture.String()}.Build().In(Db);

            var settings = new ReportingServicesSetting
            {
                Timeout = Fixture.Integer(),
                MessageSize = Fixture.Integer(),
                ReportServerBaseUrl = "www.inprotech.com/reportingserver",
                RootFolder = Fixture.String(),
                Security = new SecurityElement {Password = Fixture.String(), Username = Fixture.String(), Domain = Fixture.String()}
            };

            var subject = GetSubject(settings);

            var isSaved = await subject.Save(settings);

            Assert.True(isSaved);
        }
    }
}