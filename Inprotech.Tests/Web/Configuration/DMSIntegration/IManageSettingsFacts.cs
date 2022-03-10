using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.DMSIntegration;
using InprotechKaizen.Model.Profiles;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.DMSIntegration
{
    public class IManageSettingsFacts : FactBase
    {
        internal class IManageSettingsFixture : IFixture<IManageSettingsManager>
        {
            public ICryptoService CryptoService = Substitute.For<ICryptoService>();

            public IManageSettingsFixture(InMemoryDbContext db)
            {
                Subject = new IManageSettingsManager(db, CryptoService);
            }

            public IManageSettingsModel InvalidEmptySettings => new IManageSettingsModel
            {
                Databases = new[]
                {
                    new IManageSettings.SiteDatabaseSettings(),
                    new IManageSettings.SiteDatabaseSettings()
                }
            };

            public IManageSettingsModel ValidSetting => new IManageSettingsModel
            {
                Databases = new[]
                {
                    new IManageSettings.SiteDatabaseSettings
                    {
                        Database = "database",
                        Server = @"http://valid.com",
                        IntegrationType = "iManage Work API V2",
                        CustomerId = 1,
                        LoginType = "UsernamePassword",
                        Password = null
                    }
                },
                Disabled = true
            };

            public IManageSettingsManager Subject { get; }
        }

        [Fact]
        public async Task ShouldResolve()
        {
            var fixture = new IManageSettingsFixture(Db);
            new ExternalSettings("IManage") { Settings = "abc" }.In(Db);
            fixture.CryptoService.Decrypt(Arg.Any<string>()).ReturnsForAnyArgs("{\"Databases\":[{\"Database\":\"database\",\"Server\":\"http://valid.com\",\"IntegrationType\":\"iManage Work API V2\",\"LoginType\":\"UsernamePassword\",\"CustomerId\":1}]}");
            var data = await fixture.Subject.Resolve();
            Assert.NotNull(data);
            Assert.Equal(null, data.Databases.ElementAt(0).SiteDbId);
            Assert.Equal("database", data.Databases.ElementAt(0).Database);
        }

        [Fact]
        public async Task ShouldResolveDisabled()
        {
            var fixture = new IManageSettingsFixture(Db);
            new ExternalSettings("IManage") { Settings = "abc", IsDisabled = true }.In(Db);
            fixture.CryptoService.Decrypt(Arg.Any<string>()).ReturnsForAnyArgs("{\"Databases\":[{\"Database\":\"database\",\"Server\":\"http://valid.com\",\"IntegrationType\":\"iManage Work API V2\",\"LoginType\":\"UsernamePassword\",\"CustomerId\":1}]}");
            var data = await fixture.Subject.Resolve();
            Assert.NotNull(data);
            Assert.Equal(null, data.Databases.ElementAt(0).SiteDbId);
            Assert.True(data.Disabled);
            Assert.Equal("database", data.Databases.ElementAt(0).Database);
        }

        [Fact]
        public async Task ShouldSuccess()
        {
            var fixture = new IManageSettingsFixture(Db);
            var ex = await Record.ExceptionAsync(
                                                 () => fixture.Subject.Save(fixture.ValidSetting));
            Assert.Null(ex);

            fixture.CryptoService.Received(1).Encrypt("{\"NameTypes\":[],\"Disabled\":true,\"HasDatabaseChanges\":false,\"Databases\":[{\"Database\":\"database\",\"Server\":\"http://valid.com\",\"IntegrationType\":\"iManage Work API V2\",\"LoginType\":\"UsernamePassword\",\"CustomerId\":1}],\"Case\":{},\"NameTypesRequired\":[]}");
        }

        [Fact]
        public async Task ShouldSuccessSaveDisabled()
        {
            var fixture = new IManageSettingsFixture(Db);
            var ex = await Record.ExceptionAsync(
                                                 () => fixture.Subject.Save(fixture.ValidSetting));
            Assert.Null(ex);

            var setting = Db.Set<ExternalSettings>().SingleOrDefault(d => d.ProviderName == "IManage");
            Assert.True(setting.IsDisabled);
        }

        [Fact]
        public async Task ShouldValidateCustomerId()
        {
            var fixture = new IManageSettingsFixture(Db);
            var settings = fixture.ValidSetting;
            settings.Databases.ElementAt(0).IntegrationType = "iManage Work API V2";
            settings.Databases.ElementAt(0).CustomerId = null;
            var ex = await Record.ExceptionAsync(
                                                 () => fixture.Subject.Save(settings));
            Assert.NotNull(ex);
            Assert.Equal("Value cannot be null.", ex.Message);
            fixture.CryptoService.Received(0).Encrypt(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldValidateNullValue()
        {
            var fixture = new IManageSettingsFixture(Db);
            var ex = await Record.ExceptionAsync(
                                                 () => fixture.Subject.Save(fixture.InvalidEmptySettings));
            Assert.NotNull(ex);

            fixture.CryptoService.Received(0).Encrypt(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldValidatePassword()
        {
            var fixture = new IManageSettingsFixture(Db);
            var settings = fixture.ValidSetting;
            settings.Databases.ElementAt(0).LoginType = "UsernameWithImpersonation";
            settings.Databases.ElementAt(0).Password = null;
            var ex = await Record.ExceptionAsync(
                                                 () => fixture.Subject.Save(settings));
            Assert.NotNull(ex);
            Assert.Equal("Value cannot be null.", ex.Message);
            fixture.CryptoService.Received(0).Encrypt(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldValidateWrongValue()
        {
            var fixture = new IManageSettingsFixture(Db);
            var ex = await Record.ExceptionAsync(
                                                 () => fixture.Subject.Save(new IManageSettingsModel
                                                 {
                                                     Databases = new[]
                                                     {
                                                         new IManageSettings.SiteDatabaseSettings
                                                         {
                                                             Database = "database",
                                                             Server = @"htp://invalid..",
                                                             IntegrationType = "iManage Work API V2",
                                                             CustomerId = 1,
                                                             LoginType = "UsernamePassword",
                                                             Password = null
                                                         }
                                                     }
                                                 }));
            Assert.NotNull(ex);
            Assert.Equal("Invalid value format", ex.Message);
            fixture.CryptoService.Received(0).Encrypt(Arg.Any<string>());
        }
    }
}