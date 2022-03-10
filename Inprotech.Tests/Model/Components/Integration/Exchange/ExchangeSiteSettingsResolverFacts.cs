using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Model.Components.Integration.Exchange
{
    public class ExchangeSiteSettingsResolverFacts : FactBase
    {
        [Fact]
        public async Task ShouldReturnNoExternalSettingsIfNotFoundInDb()
        {
            var subject = new ExchangeSiteSettingsResolver(Db);

            var result = await subject.Resolve();

            Assert.False(result.ExternalSettingExists);
            Assert.False(result.HasValidSettings);
        }

        [Fact]
        public async Task ShouldReturnExternalSettings()
        {
            var ecs = new ExchangeConfigurationSettings
            {
                Domain = Fixture.String(),
                Server = Fixture.String(),
                UserName = Fixture.String(),
                Password = Fixture.String(),
                IsDraftEmailEnabled = Fixture.Boolean(),
                IsBillFinalisationEnabled = Fixture.Boolean(),
                IsReminderEnabled = Fixture.Boolean(),
                ServiceType = Fixture.String()
            };

            new ExternalSettings
            {
                IsComplete = true,
                ProviderName = KnownExternalSettings.ExchangeSetting,
                Settings = JObject.FromObject(ecs).ToString()
            }.In(Db);

            var subject = new ExchangeSiteSettingsResolver(Db);

            var result = await subject.Resolve();

            Assert.True(result.ExternalSettingExists);
            Assert.Equal(ecs.Domain, result.Settings.Domain);
            Assert.Equal(ecs.Server, result.Settings.Server);
            Assert.Equal(ecs.UserName, result.Settings.UserName);
            Assert.Equal(ecs.Password, result.Settings.Password);
            Assert.Equal(ecs.IsBillFinalisationEnabled, result.Settings.IsBillFinalisationEnabled);
            Assert.Equal(ecs.IsDraftEmailEnabled, result.Settings.IsDraftEmailEnabled);
            Assert.Equal(ecs.IsReminderEnabled, result.Settings.IsReminderEnabled);
            Assert.Equal(ecs.ServiceType, result.Settings.ServiceType);
        }
    }
}