using System;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting.VatReturns;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

#pragma warning disable 612

namespace Inprotech.Tests.Web.Accounting.Vat
{
    public class HmrcConfigurationControllerFacts
    {
        public class HmrcConfigurationControllerFixture : IFixture<HmrcConfigurationController>
        {
            public HmrcConfigurationControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                DataProtectionService = Substitute.For<ICryptoService>();
                GuidFactory = Substitute.For<Func<Guid>>();

                Substitute.For<IAppVersion>();
                Substitute.For<IAppSettingsProvider>();
                Subject = new HmrcConfigurationController(DbContext, DataProtectionService);
            }

            public InMemoryDbContext DbContext { get; set; }
            public ICryptoService DataProtectionService { get; set; }
            public Func<Guid> GuidFactory { get; set; }
            public HmrcConfigurationController Subject { get; }
            public ExternalSettings AddDefaultHmrcSettings()
            {
                const string eSettings = "{\"RedirectUri\": \"http://localhost/cpainproma/apps/hmrc/accounting/vat\", \"ClientId\": \"pfls3O23xL5xxckKDEXwxv7j7OKZIZg9RPiORCmT9i0=\", \"ClientSecret\": \"iq8E6wqWZh4+lZCEiMfrwA75c/bOzfVz8hTQlBTyppyzb9HE6RyuPlmL4QMdCujl\", \"IsProduction\": true, \"HmrcApplicationName\": \"Inprotech-Internal\"}";
                return new ExternalSettings(KnownExternalSettings.HmrcVatSettings) { Settings = eSettings }.In(DbContext);
            }
        }

        public class GetHmrcSettings : FactBase
        {
            [Fact]
            public void RetrievesCurrentHmrcSettingsAndSetsSecretToNull()
            {
                var v = new HmrcConfigurationControllerFixture(Db);
                var defaultSettings = JObject.Parse(v.AddDefaultHmrcSettings().Settings).ToObject<HmrcVatSettings>();

                var results = v.Subject.GetSettings();

                Assert.Null(results.HmrcSettings.ClientSecret);
                Assert.Equal(results.HmrcSettings.IsProduction, defaultSettings.IsProduction);
                Assert.Equal(results.HmrcSettings.RedirectUri, defaultSettings.RedirectUri);
                Assert.Equal(results.HmrcSettings.HmrcApplicationName, defaultSettings.HmrcApplicationName);
            }
        }

        public class SaveHmrcSettings : FactBase
        {
            [Fact]
            public void SaveHmrcSettingsWithProtectedSecret()
            {
                var secretToSave = Fixture.String();
                var v = new HmrcConfigurationControllerFixture(Db);

                var defaultSettings = JObject.Parse(v.AddDefaultHmrcSettings().Settings).ToObject<HmrcVatSettings>();

                defaultSettings.ClientSecret = secretToSave;
                defaultSettings.IsProduction= Fixture.Boolean();
                defaultSettings.ClientId= Fixture.String();
                defaultSettings.RedirectUri = Fixture.String();
                defaultSettings.HmrcApplicationName= Fixture.String();

                v.Subject.SaveExchangeSettings(defaultSettings);

                v.DataProtectionService.Received(1).Encrypt(secretToSave);

                var externalHmrcSetting = v.DbContext.Set<ExternalSettings>().Single(q => q.ProviderName == KnownExternalSettings.HmrcVatSettings).Settings;
                var savedHmrcSettings = JObject.Parse(externalHmrcSetting).ToObject<HmrcVatSettings>();

                Assert.Equal(defaultSettings.IsProduction, savedHmrcSettings.IsProduction);
                Assert.Equal(defaultSettings.ClientId, savedHmrcSettings.ClientId);
                Assert.Equal(defaultSettings.RedirectUri, savedHmrcSettings.RedirectUri);
                Assert.Equal(defaultSettings.HmrcApplicationName, savedHmrcSettings.HmrcApplicationName);
            }
        }
    }
}