using System;
using System.Threading.Tasks;
using Inprotech.Integration.Reports;
using Inprotech.Web.Configuration.ReportingServicesIntegration;
using InprotechKaizen.Model.Components.Integration.ReportingServices;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ReportingServicesIntegration
{
    public class ReportingSettingsControllerFacts : FactBase
    {
        [Fact]
        public async Task ValidateGetReportingSettings()
        {
            var reportingSetting = new ReportingServicesSetting
            {
                Timeout = 11,
                MessageSize = 123654,
                ReportServerBaseUrl = "http://localhost/report",
                RootFolder = "inpro",
                Security = new SecurityElement {Password = "password", Username = "username", Domain = "int"}
            };

            var f = new ReportingSettingsControllerFixture();

            f.SettingsResolver.Resolve().Returns(reportingSetting);

            var results = await f.Subject.Get();

            Assert.Equal(reportingSetting, results.Settings);
        }

        [Fact]
        public async Task ValidateSaveReportingSettings()
        {
            var f = new ReportingSettingsControllerFixture();

            f.SettingsPersistence.Save(Arg.Any<ReportingServicesSetting>()).Returns(true);

            var result = await f.Subject.Save(new ReportingServicesSetting
            {
                ReportServerBaseUrl = "http://localhost/reportserver",
                Security = new SecurityElement()
            });

            Assert.True(result.Success);
        }

        [Fact]
        public async Task SaveShouldReturnUrlFormatError()
        {
            var reportingSetting = new ReportingServicesSetting
            {
                ReportServerBaseUrl = "\\bad/url/reportingserver",
                RootFolder = "inpro",
                Security = new SecurityElement {Password = "password", Username = "username", Domain = "int"}
            };

            var f = new ReportingSettingsControllerFixture();

            var result = await f.Subject.Save(reportingSetting);

            Assert.True(result.InvalidUrl);
        }

        [Fact]
        public async Task SaveSettingsShouldThrowException()
        {
            var f = new ReportingSettingsControllerFixture();

            await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.Save(null));
        }

        [Fact]
        public async Task TestConnectionShouldReturnTrue()
        {
            var reportingSetting = new ReportingServicesSetting
            {
                Timeout = 11,
                MessageSize = 123654,
                ReportServerBaseUrl = "http://localhost/report",
                RootFolder = "inpro",
                Security = new SecurityElement {Password = "password", Username = "username", Domain = "int"}
            };

            var f = new ReportingSettingsControllerFixture();

            f.ReportClient.TestConnectionAsync(Arg.Any<ReportingServicesSetting>()).Returns(true);

            var result = await f.Subject.TestConnection(reportingSetting);

            Assert.True(result.Success);
        }

        [Fact]
        public async Task TestConnectionShouldReturnFalse()
        {
            var f = new ReportingSettingsControllerFixture();

            f.ReportClient.TestConnectionAsync(Arg.Any<ReportingServicesSetting>()).Returns(false);

            var result = await f.Subject.TestConnection(new ReportingServicesSetting());

            Assert.False(result.Success);
        }

        [Fact]
        public async Task TestConnectionShouldReturnInvalidUrl()
        {
            var reportingSetting = new ReportingServicesSetting
            {
                ReportServerBaseUrl = "\\bad/url/reportingserver",
                RootFolder = "inpro",
                Security = new SecurityElement {Password = "password", Username = "username", Domain = "int"}
            };

            var f = new ReportingSettingsControllerFixture();

            var result = await f.Subject.TestConnection(reportingSetting);

            Assert.True(result.InvalidUrl);
        }
    }

    public class ReportingSettingsControllerFixture : IFixture<ReportingServicesSettingController>
    {
        public ReportingSettingsControllerFixture()
        {
            SettingsPersistence = Substitute.For<IReportingServicesSettingsPersistence>();
            SettingsResolver = Substitute.For<IReportingServicesSettingsResolver>();
            ReportClient = Substitute.For<IReportClient>();
            Subject = new ReportingServicesSettingController(SettingsResolver, SettingsPersistence, ReportClient);
        }

        public IReportingServicesSettingsPersistence SettingsPersistence { get; }

        public IReportingServicesSettingsResolver SettingsResolver { get; }

        public IReportClient ReportClient { get; set; }

        public ReportingServicesSettingController Subject { get; }
    }
}