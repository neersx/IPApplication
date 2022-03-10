using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Web.ExchangeIntegration;
using InprotechKaizen.Model.Components.Integration.Exchange;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ExchangeIntegration
{
    public class ExchangeSettingsResolverFacts : FactBase
    {
        [Fact]
        public async Task RetrievesDefaultSettingsAndReturnsNullPassword()
        {
            var appSettingsProvider = Substitute.For<IAppSettingsProvider>();
            var exchangeSiteSettingsResolver = Substitute.For<IExchangeSiteSettingsResolver>();
            exchangeSiteSettingsResolver.Resolve().Returns(new ExchangeSiteSetting
            {
                ExternalSettingExists = true,
                HasValidSettings = true,
                Settings = new ExchangeConfigurationSettings
                {
                    Server = "S",
                    Domain = "D",
                    UserName = "U",
                    Password = "P",
                    IsReminderEnabled = true
                }
            });

            var subject = new ExchangeSettingsResolver(exchangeSiteSettingsResolver, appSettingsProvider);

            appSettingsProvider["BindingUrls"].Returns("http://*:80,https://*:443");
            var results = await subject.Resolve(Arg.Any<HttpRequestMessage>());

            Assert.Equal("D", results.Settings.Domain);
            Assert.Equal(true, results.Settings.IsReminderEnabled);
            Assert.Equal("S", results.Settings.Server);
            Assert.Equal("U", results.Settings.UserName);
            Assert.Null(results.Settings.Password);
            Assert.True(results.PasswordExists);
            Assert.NotNull(results.DefaultSiteUrls);
        }
    }
}