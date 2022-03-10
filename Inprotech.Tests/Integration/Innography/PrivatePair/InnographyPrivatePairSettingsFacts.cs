using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Caching;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Innography.PrivatePair
{
    public class InnographyPrivatePairSettingsFacts
    {
        public class ResolveMethod : FactBase
        {
            public ResolveMethod()
            {
                _cryptoService.Decrypt(Arg.Any<string>()).Returns(x => x[0]);
            }

            readonly IGroupedConfig _appSettings = Substitute.For<IGroupedConfig>();
            readonly ICryptoService _cryptoService = Substitute.For<ICryptoService>();
            readonly ILifetimeScopeCache _cache = Substitute.For<ILifetimeScopeCache>();
            readonly IInnographySettingsPersister _settingsPersister = Substitute.For<IInnographySettingsPersister>();
            readonly IAppSettingsProvider _appSettingsProvider = Substitute.For<IAppSettingsProvider>();

            InnographyPrivatePairSettings CreateSubject()
            {
                _cache.GetOrAdd(
                                Arg.Any<InnographyPrivatePairSettings>(),
                                Arg.Any<Type>(),
                                Arg.Any<Func<Type, InnographyPrivatePairSetting>>())
                      .Returns(x => ((Func<Type, InnographyPrivatePairSetting>) x[2])((Type) x[1]));

                _appSettings.GetValues("AuthenticationMode", "cpa.sso.clientId")
                            .Returns(new Dictionary<string, string>
                            {
                                {"AuthenticationMode", "Forms,Windows"}
                            });

                new ExternalSettings("Innography")
                {
                    Settings = JsonConvert.SerializeObject(SetupCreds())
                }.In(Db);

                return new InnographyPrivatePairSettings(Db, Factory, _cryptoService, _appSettingsProvider, _settingsPersister, _cache);
            }
            CredentialsMap SetupCreds()
            {
                var creds = new Dictionary<string, InnographyClientCredentials>
                {
                    {
                        "api-gateway-1", new InnographyClientCredentials
                        {
                            CryptoAlgorithm = "hmac-sha1",
                            ClientId = "innography_user_name",
                            ClientSecret = "secret"
                        }
                    },
                    {
                        "api-gateway-2", new InnographyClientCredentials
                        {
                            CryptoAlgorithm = "hmac-sha256",
                            ClientId = "inprotech-user-1",
                            ClientSecret = "secret2"
                        }
                    }
                };

                var endpoints = new Dictionary<string, string>
                {
                    {
                        "tm-dv", "api-gateway-2"
                    }
                };

                return new CredentialsMap
                {
                    Credentials = creds,
                    Endpoints = endpoints
                };
            }

            IGroupedConfig Factory(string any)
            {
                return _appSettings;
            }

            [Fact]
            public void ShouldResolveFromExternalSettings()
            {
                var ppEncrypted = new PrivatePairExternalSettings
                {
                    ClientId = Fixture.String(),
                    ClientSecret = Fixture.String(),
                    QueueSecret = Fixture.String(),
                    QueueId = Fixture.String()
                };

                new ExternalSettings("InnographyPrivatePair")
                {
                    Settings = JsonConvert.SerializeObject(ppEncrypted)
                }.In(Db);

                var subject = CreateSubject();

                var r = subject.Resolve();

                Assert.Equal(ppEncrypted.ClientId, r.PrivatePairSettings.ClientId);
                Assert.Equal(ppEncrypted.ClientSecret, r.PrivatePairSettings.ClientSecret);
                Assert.Equal(ppEncrypted.QueueSecret, r.PrivatePairSettings.QueueSecret);
                Assert.Equal(ppEncrypted.QueueId, r.PrivatePairSettings.QueueId);
            }

            [Fact]
            public void ShouldReturnEmptyPrivatePairExternalSettings()
            {
                var subject = CreateSubject();

                var r = subject.Resolve();

                Assert.Null(r.PrivatePairSettings.ClientId);
                Assert.Null(r.PrivatePairSettings.ClientSecret);
                Assert.Null(r.PrivatePairSettings.QueueSecret);
                Assert.Null(r.PrivatePairSettings.QueueId);
            }

            [Fact]
            public void ShouldReturnOverridePrivatePairBaseApiUrl()
            {
                new ExternalSettings("InnographyOverrides")
                {
                    Settings = JsonConvert.SerializeObject(new Dictionary<string, string>
                    {
                        {"pp", "https://localhost:6789/"}
                    })
                }.In(Db);

                var subject = CreateSubject();

                var r = subject.Resolve();

                Assert.Equal("https://localhost:6789/", r.PrivatePairApiBase.ToString());
            }

            [Fact]
            public void ShouldReturnAppSettingsOverridePrivatePairBaseUrl()
            {
                _appSettingsProvider["InnographyOverrides:pp"].Returns("https://localhost:6789/");

                var subject = CreateSubject();

                var r = subject.Resolve();

                Assert.Equal("https://localhost:6789/", r.PrivatePairApiBase.ToString());
            }
            
            [Fact]
            public void ShouldReturnAppSettingsOverridePrivatePairBaseUrlOverTheOtherOverride()
            {
                new ExternalSettings("InnographyOverrides")
                {
                    Settings = JsonConvert.SerializeObject(new Dictionary<string, string>
                    {
                        {"pp", "https://staging.api.innography.com"}
                    })
                }.In(Db);

                _appSettingsProvider["InnographyOverrides:pp"].Returns("https://localhost:6789/");

                var subject = CreateSubject();

                var r = subject.Resolve();

                Assert.Equal("https://localhost:6789/", r.PrivatePairApiBase.ToString());
            }
        }

        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _cryptoService.Decrypt(Arg.Any<string>()).Returns(x => x[0]);
                _cryptoService.Encrypt(Arg.Any<string>()).Returns(x => x[0]);
            }

            readonly IGroupedConfig _appSettings = Substitute.For<IGroupedConfig>();
            readonly ICryptoService _cryptoService = Substitute.For<ICryptoService>();
            readonly ILifetimeScopeCache _cache = Substitute.For<ILifetimeScopeCache>();
            readonly IInnographySettingsPersister _settingsPersister = Substitute.For<IInnographySettingsPersister>();
            readonly IAppSettingsProvider _appSettingsProvider = Substitute.For<IAppSettingsProvider>();

            InnographyPrivatePairSettings CreateSubject()
            {
                _cache.GetOrAdd(
                                Arg.Any<InnographyPrivatePairSettings>(),
                                Arg.Any<Type>(),
                                Arg.Any<Func<Type, InnographyPrivatePairSetting>>())
                      .Returns(x => ((Func<Type, InnographyPrivatePairSetting>) x[2])((Type) x[1]));

                _appSettings.GetValues("AuthenticationMode", "cpa.sso.clientId")
                            .Returns(new Dictionary<string, string>
                            {
                                {"AuthenticationMode", "Forms,Windows"}
                            });

                new ExternalSettings("Innography") 
                {
                    Settings = JsonConvert.SerializeObject(SetupCreds())
                }.In(Db);

                return new InnographyPrivatePairSettings(Db, Factory, _cryptoService, _appSettingsProvider, _settingsPersister, _cache);
            }

            CredentialsMap SetupCreds()
            {
                var creds = new Dictionary<string, InnographyClientCredentials>
                {
                    {
                        "api-gateway-1", new InnographyClientCredentials
                        {
                            CryptoAlgorithm = "hmac-sha1",
                            ClientId = "innography_user_name",
                            ClientSecret = "secret"
                        }
                    },
                    {
                        "api-gateway-2", new InnographyClientCredentials
                        {
                            CryptoAlgorithm = "hmac-sha256",
                            ClientId = "inprotech-user-1",
                            ClientSecret = "secret2"
                        }
                    }
                };

                var endpoints = new Dictionary<string, string>
                {
                    {
                        "tm-dv", "api-gateway-2"
                    }
                };

                return new CredentialsMap
                {
                    Credentials = creds,
                    Endpoints = endpoints
                };
            }

            IGroupedConfig Factory(string any)
            {
                return _appSettings;
            }

            [Fact]
            public async Task ShouldSaveSettings()
            {
                new ExternalSettings("InnographyPrivatePair")
                {
                    Settings = JsonConvert.SerializeObject(new PrivatePairExternalSettings
                    {
                        ClientId = "existing_value",
                        ClientSecret = "existing_value",
                        QueueSecret = "existing_value",
                        QueueId = "existing_value"
                    })
                }.In(Db);

                var toSave = new InnographyPrivatePairSetting
                {
                    ClientId = Fixture.String(),
                    ClientSecret = Fixture.String(),
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        ClientId = Fixture.String(),
                        ClientSecret = Fixture.String(),
                        QueueSecret = Fixture.String(),
                        QueueId = Fixture.String()
                    }
                };

                var subject = CreateSubject();

                _cache.When(_ => _.Update(subject,
                                          typeof(InnographyPrivatePairSetting),
                                          Arg.Any<InnographyPrivatePairSetting>(),
                                          Arg.Any<InnographyPrivatePairSetting>()))
                      .Do(x =>
                      {
                          var u = (InnographyPrivatePairSetting) x[3];

                          var db = Db.Set<ExternalSettings>().Single(_ => _.ProviderName == "InnographyPrivatePair");
                          db.Settings = JsonConvert.SerializeObject(new PrivatePairExternalSettings
                          {
                              ClientId = u.PrivatePairSettings.ClientId,
                              ClientSecret = u.PrivatePairSettings.ClientSecret,
                              QueueSecret = u.PrivatePairSettings.QueueSecret,
                              QueueId = u.PrivatePairSettings.QueueId
                          });
                      });

                await subject.Save(toSave);

                _settingsPersister.Received(1)
                                  .SecureAddOrUpdate("InnographyPrivatePair", toSave.PrivatePairSettings)
                                  .IgnoreAwaitForNSubstituteAssertion();

                _cache.Received(1).Update(subject, typeof(InnographyPrivatePairSetting), Arg.Any<InnographyPrivatePairSetting>(), Arg.Any<InnographyPrivatePairSetting>());

                Assert.Equal(toSave.PrivatePairSettings.ClientId, subject.Resolve().PrivatePairSettings.ClientId);
                Assert.Equal(toSave.PrivatePairSettings.ClientSecret, subject.Resolve().PrivatePairSettings.ClientSecret);
                Assert.Equal(toSave.PrivatePairSettings.QueueId, subject.Resolve().PrivatePairSettings.QueueId);
                Assert.Equal(toSave.PrivatePairSettings.QueueSecret, subject.Resolve().PrivatePairSettings.QueueSecret);
            }
        }
    }
}