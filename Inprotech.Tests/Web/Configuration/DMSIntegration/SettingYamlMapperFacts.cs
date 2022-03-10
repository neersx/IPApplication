using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Web.Configuration.DMSIntegration;
using InprotechKaizen.Model.Components.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.DMSIntegration
{
    public class SettingYamlMapperFacts
    {
        public class SettingYamlMapperFixture : IFixture<SettingYamlMapper>
        {
            public SettingYamlMapperFixture()
            {
                SiteControlReader = Substitute.For<ISiteControlReader>();
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
                Subject = new SettingYamlMapper(SiteControlReader, DisplayFormattedName);
            }

            public ISiteControlReader SiteControlReader { get; }
            public IDisplayFormattedName DisplayFormattedName { get; }
            public SettingYamlMapper Subject { get; }
        }

        [Fact]
        public async Task ShouldCallAppropriateMethodsAndReturnAppropriateMarkup()
        {
            var fixture = new SettingYamlMapperFixture();
            var nameNo = Fixture.Integer();
            var formattedName = "Complex Name with Upper Lower and Spaces";
            var setting = new IManageSettings.SiteDatabaseSettings()
            {
                ClientId = Fixture.String(),
                ClientSecret = Fixture.String(),
                CallbackUrl = Fixture.String()
            };
            fixture.SiteControlReader.Read<int>(Arg.Any<string>()).Returns(nameNo);
            fixture.DisplayFormattedName.For(nameNo).Returns(formattedName);
            var result = await fixture.Subject.GetYamlStringForSiteConfig(setting);

            fixture.SiteControlReader.Received(1).Read<int>(SiteControls.HomeNameNo);
            Assert.Equal($"id: inprotech-cnuls\r\nname: Inprotech (Complex Name with Upper Lower and Spaces)\r\npublisher: CPA Global\r\napi_key: {setting.ClientId}\r\napi_secret: {setting.ClientSecret}\r\nredirect_url: {setting.CallbackUrl}\r\nscope: user\r\n", result.ToString());
        }
        
        [Fact]
        public async Task ShouldProduceArrayMarkupForMultipleCallbackUrls()
        {
            var fixture = new SettingYamlMapperFixture();
            var nameNo = Fixture.Integer();
            var callBackUrl1 = Fixture.String();
            var callbackUrl2 = Fixture.String();
            var formattedName = "Complex Name with Upper Lower and Spaces";
            var setting = new IManageSettings.SiteDatabaseSettings()
            {
                ClientId = Fixture.String(),
                ClientSecret = Fixture.String(),
                CallbackUrl = callBackUrl1 + Environment.NewLine + callbackUrl2
            };
            fixture.SiteControlReader.Read<int>(Arg.Any<string>()).Returns(nameNo);
            fixture.DisplayFormattedName.For(nameNo).Returns(formattedName);
            var result = await fixture.Subject.GetYamlStringForSiteConfig(setting);

            fixture.SiteControlReader.Received(1).Read<int>(SiteControls.HomeNameNo);
            Assert.Equal($"id: inprotech-cnuls\r\nname: Inprotech (Complex Name with Upper Lower and Spaces)\r\npublisher: CPA Global\r\napi_key: {setting.ClientId}\r\napi_secret: {setting.ClientSecret}\r\nredirect_url:{Environment.NewLine}- {callBackUrl1}{Environment.NewLine}- {callbackUrl2}\r\nscope: user\r\n", result.ToString());
        }  

    }
}