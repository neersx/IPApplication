using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.System.Settings;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.System.Settings
{
    public class ExternalSettingFacts : FactBase
    {
        [Fact]
        public async Task ShouldResolve()
        {
            var externalSettingKey = Fixture.String();
            var fixture = new ExternalSettingFixture(Db);
            var setting = new TestModel() { Id = 1, Key = Fixture.String(), Name = Fixture.String() };
            var dbSetting = new ExternalSettings(externalSettingKey) { Settings = JsonConvert.SerializeObject(setting) }.In(Db);

            fixture.CryptoService.Decrypt(Arg.Any<string>()).ReturnsForAnyArgs(dbSetting.Settings);
            var data = await fixture.Subject.Resolve<TestModel>(externalSettingKey);
            Assert.NotNull(data);
            Assert.Equal(setting.Key, data.Key);
            Assert.Equal(setting.Name, data.Name);
            Assert.Equal(setting.Id, data.Id);
        }

        [Fact]
        public async Task ShouldAdd()
        {
            var externalSettingKey = Fixture.String();
            var fixture = new ExternalSettingFixture(Db);
            var setting = new TestModel() { Id = 1, Key = Fixture.String(), Name = Fixture.String() };
            var encrypted = JsonConvert.SerializeObject(setting);

            fixture.CryptoService.Encrypt(Arg.Any<string>()).ReturnsForAnyArgs(encrypted);
            await fixture.Subject.AddUpdate(externalSettingKey, encrypted);
            var dbSetting = Db.Set<ExternalSettings>().First();

            Assert.Equal(externalSettingKey, dbSetting.ProviderName);
            Assert.Equal(true, dbSetting.IsComplete);
            Assert.Equal(encrypted, dbSetting.Settings);
        }

        [Fact]
        public async Task ShouldUpdate()
        {
            var externalSettingKey = Fixture.String();
            var fixture = new ExternalSettingFixture(Db);

            new ExternalSettings(externalSettingKey)
            {
                Settings = JsonConvert.SerializeObject(new TestModel()
                {
                    Id = 2,
                    Key = Fixture.String(),
                    Name = Fixture.String()
                })
            }.In(Db);

            var setting = new TestModel() { Id = 1, Key = Fixture.String(), Name = Fixture.String() };
            var encrypted = JsonConvert.SerializeObject(setting);

            fixture.CryptoService.Encrypt(Arg.Any<string>()).ReturnsForAnyArgs(encrypted);
            await fixture.Subject.AddUpdate(externalSettingKey, encrypted);
            var dbSetting = Db.Set<ExternalSettings>().First();

            Assert.Equal(encrypted, dbSetting.Settings);
        }

        class TestModel
        {
            public int Id { get; set; }
            public string Name { get; set; }

            public string Key { get; set; }
        }

        class ExternalSettingFixture : IFixture<IExternalSettings>
        {
            public ExternalSettingFixture(InMemoryDbContext db)
            {
                Db = db;
                CryptoService = Substitute.For<ICryptoService>();
                Subject = new ExternalSetting(Db, CryptoService);
            }

            public IExternalSettings Subject { get; }
            public ICryptoService CryptoService { get; }

            InMemoryDbContext Db { get; }
        }
    }
}