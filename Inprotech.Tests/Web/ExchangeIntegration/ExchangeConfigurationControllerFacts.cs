using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.ExchangeIntegration;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ExchangeIntegration
{
    public class ExchangeConfigurationControllerFacts
    {
        public class ExchangeConfigurationControllerFixture : IFixture<ExchangeConfigurationController>
        {
            public ExchangeConfigurationControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;

                DataProtectionService = Substitute.For<ICryptoService>();
                IntegrationServerClient = Substitute.For<IIntegrationServerClient>();
                SecurityContext = Substitute.For<ISecurityContext>();
                ExchangeSettingsResolver = Substitute.For<IExchangeSettingsResolver>();
                Subject = new ExchangeConfigurationController(DbContext, DataProtectionService, IntegrationServerClient, SecurityContext, AppSettingsProvider, ExchangeSettingsResolver);
            }

            public InMemoryDbContext DbContext { get; set; }
            public ICryptoService DataProtectionService { get; set; }
            public IIntegrationServerClient IntegrationServerClient { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public IAppSettingsProvider AppSettingsProvider { get; set; }
            public IExchangeSettingsResolver ExchangeSettingsResolver { get; set; }
            public ExchangeConfigurationController Subject { get; }

            public ExternalSettings AddDefaultExchangeSettings()
            {
                const string eSettings = "{\"Server\": \"S\",  \"Domain\": \"D\",  \"UserName\": \"U\",  \"Password\": \"P\", \"IsReminderEnabled\": false}";
                return new ExternalSettings(KnownExternalSettings.ExchangeSetting) { Settings = eSettings }.In(DbContext);
            }
        }

        public class SaveExchangeSettings : FactBase
        {
            [Fact]
            public void SavesDefaultSettingsWithProtectedPassword()
            {
                const string savedPassword = "EncryptedPassword";
                var e = new ExchangeConfigurationControllerFixture(Db);

                var defaultSettings = JObject.Parse(e.AddDefaultExchangeSettings().Settings).ToObject<ExchangeConfigurationSettings>();
                var enteredPassword = defaultSettings.Password;

                defaultSettings.Domain = Fixture.String();
                defaultSettings.Server = Fixture.String();
                defaultSettings.UserName = Fixture.String();

                e.DataProtectionService.Encrypt(Arg.Any<string>()).Returns(savedPassword);
                e.Subject.SaveExchangeSettings(defaultSettings);

                e.DataProtectionService.Received(1).Encrypt(enteredPassword);

                var externalSetting = e.DbContext.Set<ExternalSettings>().Single(v => v.ProviderName == KnownExternalSettings.ExchangeSetting).Settings;
                var savedConfiguration = JObject.Parse(externalSetting).ToObject<ExchangeConfigurationSettings>();

                Assert.Equal(defaultSettings.Domain, savedConfiguration.Domain);
                Assert.Equal(defaultSettings.IsReminderEnabled, savedConfiguration.IsReminderEnabled);
                Assert.Equal(defaultSettings.Server, savedConfiguration.Server);
                Assert.Equal(defaultSettings.UserName, savedConfiguration.UserName);
                Assert.Equal(savedPassword, savedConfiguration.Password);
            }

            [Fact]
            public void SavesDefaultSettingsWithProtectedClientSecret()
            {
                const string savedClientSecret = "EncryptedClientSecret";
                var e = new ExchangeConfigurationControllerFixture(Db);

                var defaultSettings = JObject.Parse(e.AddDefaultExchangeSettings().Settings).ToObject<ExchangeConfigurationSettings>();

                defaultSettings.Domain = Fixture.String();
                defaultSettings.Server = Fixture.String();
                defaultSettings.UserName = Fixture.String();
                defaultSettings.ServiceType = "Graph";
                defaultSettings.ExchangeGraph = new ExchangeGraph { ClientId = Fixture.String(), TenantId = Fixture.String(), ClientSecret = Fixture.String() };
                var enteredClientSecret = defaultSettings.ExchangeGraph.ClientSecret;
                e.DataProtectionService.Encrypt(Arg.Any<string>()).Returns(savedClientSecret);
                e.Subject.SaveExchangeSettings(defaultSettings);

                e.DataProtectionService.Received(1).Encrypt(enteredClientSecret);

                var externalSetting = e.DbContext.Set<ExternalSettings>().Single(v => v.ProviderName == KnownExternalSettings.ExchangeSetting).Settings;
                var savedConfiguration = JObject.Parse(externalSetting).ToObject<ExchangeConfigurationSettings>();

                Assert.Equal(defaultSettings.IsReminderEnabled, savedConfiguration.IsReminderEnabled);
                Assert.Equal(defaultSettings.ServiceType, savedConfiguration.ServiceType);
                Assert.Equal(defaultSettings.ExchangeGraph.ClientId, savedConfiguration.ExchangeGraph.ClientId);
                Assert.Equal(defaultSettings.ExchangeGraph.TenantId, savedConfiguration.ExchangeGraph.TenantId);
                Assert.Equal(savedClientSecret, savedConfiguration.ExchangeGraph.ClientSecret);
            }
        }

        public class StatusCheck : FactBase
        {
            [Theory]
            [InlineData(true, true)]
            [InlineData(false, false)]
            public async Task RetrievesTheStatus(bool result, bool expected)
            {
                var f = new ExchangeConfigurationControllerFixture(Db);
                f.IntegrationServerClient.GetResponse(Arg.Any<string>()).Returns(new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new ObjectContent(typeof(bool), result, new JsonMediaTypeFormatter())
                });

                f.SecurityContext.User.Returns(new User(Fixture.String(), false));
                var r = await f.Subject.TestConnectivity();
                Assert.Equal(expected, r.Result);
            }

            [Theory]
            [InlineData(HttpStatusCode.Unauthorized)]
            [InlineData(HttpStatusCode.NotFound)]
            public async Task ThrowsExceptionWhenUnsuccessful(HttpStatusCode code)
            {
                var f = new ExchangeConfigurationControllerFixture(Db);
                f.IntegrationServerClient.GetResponse(Arg.Any<string>()).Returns(new HttpResponseMessage(code)
                {
                    Content = new ObjectContent(typeof(bool), true, new JsonMediaTypeFormatter())
                });
                f.SecurityContext.User.Returns(new User(Fixture.String(), false));
                try
                {
                    await f.Subject.TestConnectivity();
                }
                catch (HttpRequestException e)
                {
                    Assert.Contains(((int)code).ToString(), e.Message);
                }
            }
        }
    }
}