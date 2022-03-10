using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.Innography;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Innography
{
    public class InnographySettingsPersisterFacts
    {
        public class AddOrUpdateMethod : FactBase
        {
            readonly ICryptoService _cryptoService = Substitute.For<ICryptoService>();

            [Fact]
            public async Task ShouldCreateExternalSettingsIfNoneExist()
            {
                var providerName = "Innography" + Fixture.String();
                var data = new
                {
                    something_interesting = "hello"
                };

                var subject = new InnographySettingsPersister(Db, _cryptoService);

                await subject.AddOrUpdate(providerName, data);

                var saved = Db.Set<ExternalSettings>().Single(_ => _.ProviderName == providerName);

                Assert.Equal(JsonConvert.SerializeObject(data), saved.Settings);
                Assert.True(saved.IsComplete);
            }

            [Fact]
            public async Task ShouldThrowForNonInnographyRelatedSettings()
            {
                var subject = new InnographySettingsPersister(Db, _cryptoService);

                await Assert.ThrowsAnyAsync<Exception>(async () => await subject.AddOrUpdate(Fixture.String(), new { }));
            }

            [Fact]
            public async Task ShouldUpdateExternalSettingsIfExisted()
            {
                var providerName = "Innography" + Fixture.String();

                new ExternalSettings(providerName)
                {
                    Settings = JsonConvert.SerializeObject(new
                    {
                        something_interesting = "hello"
                    })
                }.In(Db);

                var newData = new
                {
                    something_interesting = "hello world"
                };

                var subject = new InnographySettingsPersister(Db, _cryptoService);

                await subject.AddOrUpdate(providerName, newData);

                var saved = Db.Set<ExternalSettings>().Single(_ => _.ProviderName == providerName);

                Assert.Equal(JsonConvert.SerializeObject(newData), saved.Settings);
                Assert.True(saved.IsComplete);
            }
        }

        public class SecureAddOrUpdateMethod : FactBase
        {
            readonly ICryptoService _cryptoService = Substitute.For<ICryptoService>();

            [Fact]
            public async Task ShouldCreateExternalSettingsIfNoneExist()
            {
                var providerName = "Innography" + Fixture.String();

                _cryptoService.Encrypt(Arg.Any<string>())
                              .Returns("{ encrypted: true }");

                var subject = new InnographySettingsPersister(Db, _cryptoService);

                await subject.SecureAddOrUpdate(providerName, new
                {
                    something_interesting = Fixture.String()
                });

                var saved = Db.Set<ExternalSettings>().Single(_ => _.ProviderName == providerName);

                Assert.Equal("{ encrypted: true }", saved.Settings);
                Assert.True(saved.IsComplete);
            }

            [Fact]
            public async Task ShouldThrowForNonInnographyRelatedSettings()
            {
                var subject = new InnographySettingsPersister(Db, _cryptoService);

                await Assert.ThrowsAnyAsync<Exception>(async () => await subject.SecureAddOrUpdate(Fixture.String(), new { }));
            }

            [Fact]
            public async Task ShouldUpdateExternalSettingsIfExisted()
            {
                var providerName = "Innography" + Fixture.String();

                new ExternalSettings(providerName)
                {
                    Settings = Fixture.String()
                }.In(Db);

                var subject = new InnographySettingsPersister(Db, _cryptoService);

                _cryptoService.Encrypt(Arg.Any<string>())
                              .Returns("{ encrypted: true }");

                await subject.SecureAddOrUpdate(providerName, new { });

                var saved = Db.Set<ExternalSettings>().Single(_ => _.ProviderName == providerName);

                Assert.Equal("{ encrypted: true }", saved.Settings);
                Assert.True(saved.IsComplete);
            }
        }
    }
}