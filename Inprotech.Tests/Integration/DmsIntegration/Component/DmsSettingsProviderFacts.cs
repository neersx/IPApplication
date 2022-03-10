using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

#pragma warning disable 612

namespace Inprotech.Tests.Integration.DmsIntegration.Component
{
    public class DmsSettingsProviderFacts : FactBase
    {
        readonly ICryptoService _cryptoService = Substitute.For<ICryptoService>();
        readonly IConfiguredDms _configuredDms = Substitute.For<IConfiguredDms>();

        DmsSettingsProvider CreateSubject()
        {
            _cryptoService.Decrypt(Arg.Any<string>())
                          .Returns(x => x[0]);

            _configuredDms.GetSettingMetaData()
                          .Returns((KnownExternalSettings.IManage, typeof(IManageSettings)));

            return new DmsSettingsProvider(Db, _configuredDms, _cryptoService);
        }

        [Fact]
        public async Task ShouldResolveIManageSettings()
        {
            var databaseName = Fixture.String();
            var databaseName2 = Fixture.String();
            var integrationType = Fixture.String();
            var loginType = Fixture.String();
            var password = Fixture.String();
            var server = Fixture.String();
            var server2 = Fixture.String();
            var searchField = Fixture.String();
            var subtype = Fixture.String();
            var subclass = Fixture.String();
            var nameTypeSubClass = Fixture.String();
            var nameType = Fixture.String();

            new ExternalSettings
            {
                ProviderName = KnownExternalSettings.IManage,
                IsDisabled = true,
                Settings = JsonConvert.SerializeObject(new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            CustomerId = 1,
                            Database = databaseName,
                            IntegrationType = integrationType,
                            LoginType = loginType,
                            Password = password,
                            Server = server
                        },
                        new IManageSettings.SiteDatabaseSettings
                        {
                            CustomerId = 1,
                            Database = databaseName2,
                            IntegrationType = IManageSettings.IntegrationTypes.iManageWorkApiV2,
                            LoginType = IManageSettings.LoginTypes.OAuth,
                            AccessTokenUrl = $"'http://{server2}",
                            AuthUrl = $"'http://{server2}",
                            Password = password,
                            Server = server2
                        }
                    },
                    Case = new IManageSettings.CaseSettings
                    {
                        SearchField = searchField,
                        SubClass = subclass,
                        SubType = subtype
                    },
                    NameTypes = new[]
                    {
                        new IManageSettings.NameTypeSettings
                        {
                            NameType = nameType,
                            SubClass = nameTypeSubClass
                        }
                    }
                })
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Provide() as IManageSettings;

            Assert.NotNull(r);
            Assert.Equal(r.Databases.First().Server, server);
            Assert.Equal(r.Databases.First().Database, databaseName);
            Assert.Equal(r.Databases.First().IntegrationType, integrationType);
            Assert.Equal(r.Databases.First().CustomerId, 1);
            Assert.Equal(r.Databases.First().LoginType, loginType);
            Assert.Equal(r.Databases.First().Password, password);
            Assert.Equal(r.Case.SearchField, searchField);
            Assert.Equal(r.Case.SubType, subtype);
            Assert.Equal(r.Case.SubClass, subclass);
            Assert.Equal(r.NameTypes.First().NameType, nameType);
            Assert.Equal(r.NameTypes.First().SubClass, nameTypeSubClass);
            Assert.True(r.Disabled);

            var o = (await subject.OAuth2Setting()).ToArray();
            Assert.Equal(o.Single().Server, server2);
            Assert.Equal(o.Single().Database, databaseName2);
            Assert.Equal(o.Single().IntegrationType, IManageSettings.IntegrationTypes.iManageWorkApiV2);
            Assert.Equal(o.Single().CustomerId, 1);
            Assert.Equal(o.Single().LoginType, IManageSettings.LoginTypes.OAuth);
            Assert.Equal(o.Single().AuthUrl, $"'http://{server2}");
            Assert.Equal(o.Single().AccessTokenUrl, $"'http://{server2}");
        }

        [Fact]
        public async Task ShouldReturnEmptySettingsWhenSettingInDbButUnset()
        {
            new ExternalSettings
            {
                ProviderName = KnownExternalSettings.IManage,
                Settings = null
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Provide();

            Assert.IsType<DmsSettings>(r);
            Assert.NotNull(r);
        }

        [Fact]
        public async Task ShouldReturnEmptySettingsWhenSettingNotFoundInDb()
        {
            var subject = CreateSubject();

            var r = await subject.Provide();

            Assert.IsType<DmsSettings>(r);
            Assert.NotNull(r);
        }
    }
}