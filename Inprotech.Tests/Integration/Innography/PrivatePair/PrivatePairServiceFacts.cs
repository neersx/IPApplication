using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Innography.PrivatePair
{
    public class PrivatePairServiceFacts
    {
        const string PrivatePairApiVersion = "0.9";

        class PrivatePairServiceFixture : IFixture<PrivatePairService>
        {
            public PrivatePairServiceFixture(InnographyPrivatePairSetting settings = null, string validEnvironment = null)
            {
                if (!string.IsNullOrWhiteSpace(validEnvironment))
                {
                    ValidEnvironment = validEnvironment;
                }

                Setting = settings ?? new InnographyPrivatePairSetting
                {
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        ValidEnvironment = ValidEnvironment
                    },
                    ValidEnvironment = ValidEnvironment
                };

                HostInfo HostInfoResolver()
                {
                    return new HostInfo { DbIdentifier = ValidEnvironment };
                }

                Settings = Substitute.For<IInnographyPrivatePairSettings>();
                Settings.Resolve().Returns(Setting);

                Client = Substitute.For<IInnographyClient>();
                CryptographyService = Substitute.For<ICryptographyService>();

                Subject = new PrivatePairService(Settings, Client, CryptographyService, HostInfoResolver);
            }

            public string ValidEnvironment { get; } = Fixture.String();

            public IInnographyPrivatePairSettings Settings { get; }

            public IInnographyClient Client { get; }

            public ICryptographyService CryptographyService { get; }

            public InnographyPrivatePairSetting Setting { get; }

            public PrivatePairService Subject { get; }
        }

        public class CheckOrCreateAccountMethod
        {
            [Fact]
            public async Task ShouldCreateThenSaveTheAccount()
            {
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();
                var queueId = Fixture.String();
                var queueSecret = Fixture.String();
                var sqsRegion = Fixture.String();

                var fixture = new PrivatePairServiceFixture();

                fixture.Client
                       .Post<string>(Arg.Any<InnographyClientSettings>(), new Uri("https://api.innography.com/private-pair/account"))
                       .Returns(JsonConvert.SerializeObject(new
                       {
                           status = "success",
                           result = new
                           {
                               account_id = accountId,
                               account_secret = accountSecret,
                               queue_access_id = queueId,
                               queue_access_secret = queueSecret,
                               sqs_region = sqsRegion
                           }
                       }));

                await fixture.Subject.CheckOrCreateAccount();

                fixture.Settings
                       .Received(1)
                       .Save(Arg.Is<InnographyPrivatePairSetting>(x =>
                                                                      accountId == x.PrivatePairSettings.ClientId
                                                                      && accountSecret == x.PrivatePairSettings.ClientSecret
                                                                      && queueId == x.PrivatePairSettings.QueueId
                                                                      && queueSecret == x.PrivatePairSettings.QueueSecret
                                                                      && sqsRegion == x.PrivatePairSettings.SqsRegion
                                                                      && fixture.ValidEnvironment == x.PrivatePairSettings.ValidEnvironment
                                                                 )).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldExitIfAccountDetailsExist()
            {
                var fixture = new PrivatePairServiceFixture();

                fixture.Setting.PrivatePairSettings.QueueSecret = Fixture.String();
                fixture.Setting.PrivatePairSettings.QueueId = Fixture.String();
                fixture.Setting.PrivatePairSettings.ClientSecret = Fixture.String();
                fixture.Setting.PrivatePairSettings.ClientId = Fixture.String();

                await fixture.Subject.CheckOrCreateAccount();

                fixture.Client
                       .DidNotReceive()
                       .Post<string>(Arg.Any<InnographyClientSettings>(), Arg.Is<Uri>(_ => _.ToString() == "https://api.innography.com/private-pair/account"))
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class UpdateServiceMethod
        {
            [Fact]
            public async Task ShouldCheckEnvironmentThatConsidersOverride()
            {
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();
                var queueId = Fixture.String();
                var queueSecret = Fixture.String();
                var sqsRegion = Fixture.String();
                var environment = "same environment";
                var serviceId = "10001";
                var payload = new SponsorshipModel { ServiceId = serviceId, Password = "password", CustomerNumbers = "12345,34556" };

                var fixture = new PrivatePairServiceFixture(new InnographyPrivatePairSetting
                {
                    ClientId = Fixture.String(),
                    ClientSecret = Fixture.String(),
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        QueueId = queueId,
                        QueueSecret = queueSecret,
                        ClientId = accountId,
                        ClientSecret = accountSecret,
                        ValidEnvironment = "different environment",
                        Services = new Dictionary<string, ServiceCredentials>
                        {
                            {serviceId, new ServiceCredentials()}
                        }
                    },
                    ValidEnvironment = environment
                }, environment);

                fixture.Client
                       .Patch<string>(Arg.Any<InnographyClientSettings>(), Arg.Any<Uri>(), Arg.Any<PrivatePairServiceModel>())
                       .Returns(JsonConvert.SerializeObject(new
                       {
                           status = "success",
                           result = new
                           {
                               account_id = accountId,
                               account_secret = accountSecret,
                               queue_access_id = queueId,
                               queue_access_secret = queueSecret,
                               sqs_region = sqsRegion
                           }
                       }));

                await fixture.Subject.UpdateServiceDetails(payload.ServiceId, payload.Password, payload.AuthenticatorKey, payload.CustomerNumbers.Split(','));

                await fixture.Client
                             .Received(1)
                             .Patch<string>(Arg.Any<InnographyClientSettings>(), new Uri($"https://api.innography.com/private-pair/account/{accountId}/service/uspto/{serviceId}"), Arg.Is<PrivatePairServiceModel>(p => p.Password == payload.Password));
            }

            [Fact]
            public async Task ShouldNotUpdateIfEnvironmentIsDifferent()
            {
                var serviceId = "10001";
                var payload = new SponsorshipModel { ServiceId = serviceId, Password = "password", CustomerNumbers = "12345,34556" };

                var fixture = new PrivatePairServiceFixture(new InnographyPrivatePairSetting
                {
                    ClientId = Fixture.String(),
                    ClientSecret = Fixture.String(),
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        QueueId = Fixture.String(),
                        QueueSecret = Fixture.String(),
                        ClientId = Fixture.String(),
                        ClientSecret = Fixture.String(),
                        ValidEnvironment = "different environment",
                        Services = new Dictionary<string, ServiceCredentials>
                        {
                            {serviceId, new ServiceCredentials()}
                        }
                    },
                    ValidEnvironment = "different environment"
                });

                var r = await fixture.Subject.UpdateServiceDetails(payload.ServiceId, payload.Password, payload.AuthenticatorKey, payload.CustomerNumbers.Split(','));

                await fixture.Client.DidNotReceiveWithAnyArgs().Patch<string>(null, null, null);

                Assert.False(r.Updated);

                Assert.Equal("invalidEnvironment", r.Reason);
            }

            [Fact]
            public async Task ShouldNotUpdateIfServiceNotRegistered()
            {
                var payload = new SponsorshipModel { ServiceId = "10001", Password = "password", CustomerNumbers = "12345,34556" };

                var fixture = new PrivatePairServiceFixture();
                var result = await fixture.Subject.UpdateServiceDetails(payload.ServiceId, payload.Password, payload.AuthenticatorKey, payload.CustomerNumbers.Split(','));

                Assert.False(result.Updated);

                await fixture.Client
                             .DidNotReceiveWithAnyArgs()
                             .Patch<string>(Arg.Any<InnographyClientSettings>(), new Uri("https://api.innography.com/private-pair/account//service/uspto/" + payload.ServiceId), Arg.Is<PrivatePairServiceModel>(p => p.Password == payload.Password));
            }

            [Fact]
            public async Task ShouldSetEmptyStringsToNull()
            {
                var innographyClientId = Fixture.String();
                var innographyClientSecret = Fixture.String();
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();
                var queueId = Fixture.String();
                var queueSecret = Fixture.String();
                var sqsRegion = Fixture.String();
                var environment = Fixture.String();
                var serviceId = "10001";
                var payload = new SponsorshipModel { ServiceId = serviceId, Password = string.Empty, CustomerNumbers = "12345,34556" };

                var fixture = new PrivatePairServiceFixture(new InnographyPrivatePairSetting
                {
                    ClientId = innographyClientId,
                    ClientSecret = innographyClientSecret,
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        QueueId = queueId,
                        QueueSecret = queueSecret,
                        ClientId = accountId,
                        ClientSecret = accountSecret,
                        ValidEnvironment = environment,
                        Services = new Dictionary<string, ServiceCredentials>
                        {
                            {serviceId, new ServiceCredentials()}
                        }
                    },
                    ValidEnvironment = environment
                }, environment);

                fixture.Client
                       .Patch<string>(Arg.Any<InnographyClientSettings>(), Arg.Any<Uri>(), Arg.Any<PrivatePairServiceModel>())
                       .Returns(JsonConvert.SerializeObject(new
                       {
                           status = "success",
                           result = new
                           {
                               account_id = accountId,
                               account_secret = accountSecret,
                               queue_access_id = queueId,
                               queue_access_secret = queueSecret,
                               sqs_region = sqsRegion
                           }
                       }));

                await fixture.Subject.UpdateServiceDetails(payload.ServiceId, payload.Password, payload.AuthenticatorKey, payload.CustomerNumbers.Split(','));

                await fixture.Client
                             .Received(1)
                             .Patch<string>(Arg.Any<InnographyClientSettings>(), new Uri($"https://api.innography.com/private-pair/account/{accountId}/service/uspto/{serviceId}"),
                                            Arg.Is<PrivatePairServiceModel>(p => p.Password == null && p.Secret == null));
            }

            [Fact]
            public async Task ShouldUpdateAccount()
            {
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();
                var queueId = Fixture.String();
                var queueSecret = Fixture.String();
                var sqsRegion = Fixture.String();
                var environment = Fixture.String();
                var serviceId = "10001";
                var payload = new SponsorshipModel { ServiceId = serviceId, Password = "password", CustomerNumbers = "12345,34556" };

                var fixture = new PrivatePairServiceFixture(new InnographyPrivatePairSetting
                {
                    ClientId = Fixture.String(),
                    ClientSecret = Fixture.String(),
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        QueueId = queueId,
                        QueueSecret = queueSecret,
                        ClientId = accountId,
                        ClientSecret = accountSecret,
                        ValidEnvironment = environment,
                        Services = new Dictionary<string, ServiceCredentials>
                        {
                            {serviceId, new ServiceCredentials()}
                        }
                    },
                    ValidEnvironment = environment
                }, environment);

                fixture.Client
                       .Patch<string>(Arg.Any<InnographyClientSettings>(), Arg.Any<Uri>(), Arg.Any<PrivatePairServiceModel>())
                       .Returns(JsonConvert.SerializeObject(new
                       {
                           status = "success",
                           result = new
                           {
                               account_id = accountId,
                               account_secret = accountSecret,
                               queue_access_id = queueId,
                               queue_access_secret = queueSecret,
                               sqs_region = sqsRegion
                           }
                       }));

                await fixture.Subject.UpdateServiceDetails(payload.ServiceId, payload.Password, payload.AuthenticatorKey, payload.CustomerNumbers.Split(','));

                await fixture.Client
                             .Received(1)
                             .Patch<string>(Arg.Any<InnographyClientSettings>(), new Uri($"https://api.innography.com/private-pair/account/{accountId}/service/uspto/{serviceId}"), Arg.Is<PrivatePairServiceModel>(p => p.Password == payload.Password));
            }
        }

        public class GlobalAccountSettingsServiceMethod
        {
            [Fact]
            public async Task ShouldCheckEnvironmentThatConsidersOverride()
            {
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();
                var queueId = Fixture.String();
                var queueSecret = Fixture.String();
                var sqsRegion = Fixture.String();
                var environment = "same environment";
                var serviceId = "10001";
                var payload = new { Start = Fixture.PastDate(), End = Fixture.Today(), QueueId = Fixture.String(), QueueSecret = Fixture.String(), QueueUrl = Fixture.String() };

                var fixture = new PrivatePairServiceFixture(new InnographyPrivatePairSetting
                {
                    ClientId = Fixture.String(),
                    ClientSecret = Fixture.String(),
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        QueueId = queueId,
                        QueueSecret = queueSecret,
                        ClientId = accountId,
                        ClientSecret = accountSecret,
                        ValidEnvironment = "different environment",
                        Services = new Dictionary<string, ServiceCredentials>
                        {
                            {serviceId, new ServiceCredentials()}
                        }
                    },
                    ValidEnvironment = environment
                }, environment);

                fixture.Client
                       .Post<string>(Arg.Any<InnographyClientSettings>(), Arg.Any<Uri>(), Arg.Any<object>())
                       .Returns(JsonConvert.SerializeObject(new
                       {
                           status = "success",
                           result = new
                           {
                               account_id = accountId,
                               account_secret = accountSecret,
                               queue_access_id = queueId,
                               queue_access_secret = queueSecret,
                               sqs_region = sqsRegion
                           }
                       }));

                await fixture.Subject.UpdateOneTimeGlobalAccountSettings(payload.Start, payload.End, payload.QueueId, payload.QueueSecret, payload.QueueUrl);

                await fixture.Client
                             .Received(1)
                             .Post<string>(Arg.Any<InnographyClientSettings>(), new Uri($"https://api.innography.com/private-pair/account/{accountId}/queue"),
                                            Arg.Any<object>());
            }

            [Fact]
            public async Task ShouldNotUpdateIfEnvironmentIsDifferent()
            {
                var serviceId = "10001";
                var payload = new { Start = Fixture.PastDate(), End = Fixture.Today(), QueueId = Fixture.String(), QueueSecret = Fixture.String(), QueueUrl = Fixture.String() };

                var fixture = new PrivatePairServiceFixture(new InnographyPrivatePairSetting
                {
                    ClientId = Fixture.String(),
                    ClientSecret = Fixture.String(),
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        QueueId = Fixture.String(),
                        QueueSecret = Fixture.String(),
                        ClientId = Fixture.String(),
                        ClientSecret = Fixture.String(),
                        ValidEnvironment = "different environment",
                        Services = new Dictionary<string, ServiceCredentials>
                        {
                            {serviceId, new ServiceCredentials()}
                        }
                    },
                    ValidEnvironment = "different environment"
                });

                var r = await fixture.Subject.UpdateOneTimeGlobalAccountSettings(payload.Start, payload.End, payload.QueueId, payload.QueueSecret, payload.QueueUrl);

                await fixture.Client.DidNotReceiveWithAnyArgs().Patch<string>(null, null, null);

                Assert.False(r.Updated);

                Assert.Equal("invalidEnvironment", r.Reason);
            }

            [Fact]
            public async Task ShouldRequeue()
            {
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();
                var queueId = Fixture.String();
                var queueSecret = Fixture.String();
                var sqsRegion = Fixture.String();
                var environment = Fixture.String();
                var serviceId = "10001";
                var payload = new { Start = Fixture.PastDate(), End = Fixture.Today(), QueueId = Fixture.String(), QueueSecret = Fixture.String(), QueueUrl = Fixture.String() };

                var fixture = new PrivatePairServiceFixture(new InnographyPrivatePairSetting
                {
                    ClientId = Fixture.String(),
                    ClientSecret = Fixture.String(),
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        QueueId = queueId,
                        QueueSecret = queueSecret,
                        ClientId = accountId,
                        ClientSecret = accountSecret,
                        ValidEnvironment = environment,
                        Services = new Dictionary<string, ServiceCredentials>
                        {
                            {serviceId, new ServiceCredentials()}
                        }
                    },
                    ValidEnvironment = environment
                }, environment);

                fixture.Client
                       .Post<string>(Arg.Any<InnographyClientSettings>(), Arg.Any<Uri>(), Arg.Any<object>())
                       .Returns(JsonConvert.SerializeObject(new
                       {
                           status = "success",
                           result = new
                           {
                               account_id = accountId,
                               account_secret = accountSecret,
                               queue_access_id = queueId,
                               queue_access_secret = queueSecret,
                               sqs_region = sqsRegion
                           }
                       }));

                await fixture.Subject.UpdateOneTimeGlobalAccountSettings(payload.Start, payload.End, payload.QueueId, payload.QueueSecret, payload.QueueUrl);

                await fixture.Client
                             .Received(1)
                             .Post<string>(Arg.Any<InnographyClientSettings>(), new Uri($"https://api.innography.com/private-pair/account/{accountId}/queue"),
                                            Arg.Any<object>());

                Assert.Equal(payload.QueueId, fixture.Setting.PrivatePairSettings.QueueId);
                Assert.Equal(payload.QueueUrl, fixture.Setting.PrivatePairSettings.QueueUrl);
                Assert.Equal(payload.QueueSecret, fixture.Setting.PrivatePairSettings.QueueSecret);
            }
        }

        public class DeleteAccountMethod
        {
            [Fact]
            public async Task ShouldCheckEnvironmentThatConsidersOverride()
            {
                var innographyClientId = Fixture.String();
                var innographyClientSecret = Fixture.String();
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();
                var queueId = Fixture.String();
                var queueSecret = Fixture.String();
                var environment = "same environment";
                var fixture = new PrivatePairServiceFixture(new InnographyPrivatePairSetting
                {
                    ClientId = innographyClientId,
                    ClientSecret = innographyClientSecret,
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        QueueId = queueId,
                        QueueSecret = queueSecret,
                        ClientId = accountId,
                        ClientSecret = accountSecret,
                        ValidEnvironment = "different environment"
                    },
                    ValidEnvironment = environment
                }, environment);

                await fixture.Subject.DeleteAccount();

                fixture.Client
                       .Delete(Arg.Is<InnographyClientSettings>(_ => _.ClientId == accountId
                                                                     && _.ClientSecret == accountSecret
                                                                     && _.Version == PrivatePairApiVersion),
                               new Uri($"https://api.innography.com/private-pair/account/{accountId}"))
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.Settings
                       .Received(1)
                       .Save(Arg.Is<InnographyPrivatePairSetting>(x =>
                                                                      string.IsNullOrWhiteSpace(x.PrivatePairSettings.ClientId)
                                                                      && string.IsNullOrWhiteSpace(x.PrivatePairSettings.ClientSecret)
                                                                      && string.IsNullOrWhiteSpace(x.PrivatePairSettings.QueueId)
                                                                      && string.IsNullOrWhiteSpace(x.PrivatePairSettings.QueueSecret)
                                                                 )).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldDeleteTheAccount()
            {
                var innographyClientId = Fixture.String();
                var innographyClientSecret = Fixture.String();
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();
                var queueId = Fixture.String();
                var queueSecret = Fixture.String();
                var environment = Fixture.String();
                var fixture = new PrivatePairServiceFixture(new InnographyPrivatePairSetting
                {
                    ClientId = innographyClientId,
                    ClientSecret = innographyClientSecret,
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        QueueId = queueId,
                        QueueSecret = queueSecret,
                        ClientId = accountId,
                        ClientSecret = accountSecret,
                        ValidEnvironment = environment
                    },
                    ValidEnvironment = environment
                }, environment);

                await fixture.Subject.DeleteAccount();

                fixture.Client
                       .Delete(Arg.Is<InnographyClientSettings>(_ => _.ClientId == accountId
                                                                     && _.ClientSecret == accountSecret
                                                                     && _.Version == PrivatePairApiVersion),
                               new Uri($"https://api.innography.com/private-pair/account/{accountId}"))
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.Settings
                       .Received(1)
                       .Save(Arg.Is<InnographyPrivatePairSetting>(x =>
                                                                      string.IsNullOrWhiteSpace(x.PrivatePairSettings.ClientId)
                                                                      && string.IsNullOrWhiteSpace(x.PrivatePairSettings.ClientSecret)
                                                                      && string.IsNullOrWhiteSpace(x.PrivatePairSettings.QueueId)
                                                                      && string.IsNullOrWhiteSpace(x.PrivatePairSettings.QueueSecret)
                                                                 )).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldExitIfAccountDetailsDidNotExist()
            {
                var fixture = new PrivatePairServiceFixture();

                await fixture.Subject.DeleteAccount();

                fixture.Client
                       .DidNotReceive()
                       .Delete(Arg.Any<InnographyClientSettings>(), Arg.Any<Uri>())
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldFakeDeleteTheAccountIfEnvironmentIsDifferent()
            {
                var innographyClientId = Fixture.String();
                var innographyClientSecret = Fixture.String();
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();
                var queueId = Fixture.String();
                var queueSecret = Fixture.String();
                var environment = Fixture.String();

                var fixture = new PrivatePairServiceFixture(new InnographyPrivatePairSetting
                {
                    ClientId = innographyClientId,
                    ClientSecret = innographyClientSecret,
                    PrivatePairSettings = new PrivatePairExternalSettings
                    {
                        QueueId = queueId,
                        QueueSecret = queueSecret,
                        ClientId = accountId,
                        ClientSecret = accountSecret,
                        ValidEnvironment = environment
                    },
                    ValidEnvironment = environment
                });

                await fixture.Subject.DeleteAccount();

                fixture.Client
                       .DidNotReceiveWithAnyArgs()
                       .Delete(null, null).IgnoreAwaitForNSubstituteAssertion();

                fixture.Settings
                       .Received(1)
                       .Save(Arg.Is<InnographyPrivatePairSetting>(x =>
                                                                      string.IsNullOrWhiteSpace(x.PrivatePairSettings.ClientId)
                                                                      && string.IsNullOrWhiteSpace(x.PrivatePairSettings.ClientSecret)
                                                                      && string.IsNullOrWhiteSpace(x.PrivatePairSettings.QueueId)
                                                                      && string.IsNullOrWhiteSpace(x.PrivatePairSettings.QueueSecret)
                                                                 )).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DispatchCrawlerServiceMethod
        {
            [Fact]
            public async Task ShouldDispatchThenSaveTheService()
            {
                var fixture = new PrivatePairServiceFixture();

                var returnServiceId = Fixture.String();
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();
                var queueId = Fixture.String();
                var queueSecret = Fixture.String();
                var pw = Fixture.String();
                var accountEmail = Fixture.String() + "@cpaglobal.com";
                var secretCode = Fixture.String();
                var sponsor = Fixture.String();
                var customerNumbers = Enumerable.Range(0, Fixture.Short(10))
                                                .Select(_ => Fixture.Integer().ToString())
                                                .ToArray();
                var keySet = new KeySet
                {
                    Public = Fixture.String(),
                    Private = Fixture.String()
                };

                fixture.Setting.PrivatePairSettings.QueueId = queueId;
                fixture.Setting.PrivatePairSettings.QueueSecret = queueSecret;
                fixture.Setting.PrivatePairSettings.ClientId = accountId;
                fixture.Setting.PrivatePairSettings.ClientSecret = accountSecret;

                fixture.CryptographyService.GenerateRsaKeys(4096)
                       .Returns(keySet);

                fixture.Client
                       .Post<string>(
                                     Arg.Any<InnographyClientSettings>(),
                                     new Uri($"https://api.innography.com/private-pair/account/{accountId}/service/uspto"),
                                     Arg.Any<PrivatePairCredentials>())
                       .Returns(JsonConvert.SerializeObject(new
                       {
                           status = "success",
                           result = new
                           {
                               service_id = returnServiceId
                           }
                       }));

                var result = await fixture.Subject.DispatchCrawlerService(accountEmail, pw, secretCode, sponsor, customerNumbers);

                Assert.Equal(result, returnServiceId);

                fixture.Client
                       .Received(1)
                       .Post<string>(Arg.Is<InnographyClientSettings>(_ => _.ClientId == accountId
                                                                           && _.ClientSecret == accountSecret
                                                                           && _.Version == PrivatePairApiVersion),
                                     new Uri($"https://api.innography.com/private-pair/account/{accountId}/service/uspto"),
                                     Arg.Is<PrivatePairCredentials>(_ => _.Sponsor == sponsor
                                                                         && _.Password == pw
                                                                         && _.Email == accountEmail
                                                                         && _.SecretCode == secretCode
                                                                         && _.PublicKey == keySet.Public))
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.Settings
                       .Received(1)
                       .Save(Arg.Is<InnographyPrivatePairSetting>(x =>
                                                                      returnServiceId == x.PrivatePairSettings.Services[returnServiceId].Id
                                                                      && keySet.Public == x.PrivatePairSettings.Services[returnServiceId].KeySet.Public
                                                                      && keySet.Private == x.PrivatePairSettings.Services[returnServiceId].KeySet.Private
                                                                 )).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DecommissionCrawlerServiceMethod
        {
            [Fact]
            public async Task ShouldCheckEnvironmentThatConsidersOverride()
            {
                var fixture = new PrivatePairServiceFixture();

                var serviceId = Fixture.String();
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();

                fixture.Setting.PrivatePairSettings.QueueId = Fixture.String();
                fixture.Setting.PrivatePairSettings.QueueSecret = Fixture.String();
                fixture.Setting.PrivatePairSettings.ClientId = accountId;
                fixture.Setting.PrivatePairSettings.ClientSecret = accountSecret;
                fixture.Setting.PrivatePairSettings.ValidEnvironment = Fixture.String();
                fixture.Setting.PrivatePairSettings.Services.Add(serviceId, new ServiceCredentials());

                await fixture.Subject.DecommissionCrawlerService(serviceId);

                fixture.Client
                       .Received(1)
                       .Delete(Arg.Is<InnographyClientSettings>(_ => _.ClientId == accountId
                                                                     && _.ClientSecret == accountSecret
                                                                     && _.Version == PrivatePairApiVersion),
                               new Uri($"https://api.innography.com/private-pair/account/{accountId}/service/uspto/{serviceId}"))
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.Settings
                       .Received(1)
                       .Save(Arg.Is<InnographyPrivatePairSetting>(x => !x.PrivatePairSettings.Services.ContainsKey(serviceId))).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldDeleteServiceThenSave()
            {
                var fixture = new PrivatePairServiceFixture();

                var serviceId = Fixture.String();
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();

                fixture.Setting.PrivatePairSettings.QueueId = Fixture.String();
                fixture.Setting.PrivatePairSettings.QueueSecret = Fixture.String();
                fixture.Setting.PrivatePairSettings.ClientId = accountId;
                fixture.Setting.PrivatePairSettings.ClientSecret = accountSecret;
                fixture.Setting.PrivatePairSettings.Services.Add(serviceId, new ServiceCredentials());

                await fixture.Subject.DecommissionCrawlerService(serviceId);

                fixture.Client
                       .Received(1)
                       .Delete(Arg.Is<InnographyClientSettings>(_ => _.ClientId == accountId
                                                                     && _.ClientSecret == accountSecret
                                                                     && _.Version == PrivatePairApiVersion),
                               new Uri($"https://api.innography.com/private-pair/account/{accountId}/service/uspto/{serviceId}"))
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.Settings
                       .Received(1)
                       .Save(Arg.Is<InnographyPrivatePairSetting>(x => !x.PrivatePairSettings.Services.ContainsKey(serviceId))).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldFakeDeleteServiceThenSaveIfEnvironmentIsDifferent()
            {
                var fixture = new PrivatePairServiceFixture();

                var serviceId = Fixture.String();
                var accountId = Fixture.String();
                var accountSecret = Fixture.String();

                fixture.Setting.PrivatePairSettings.QueueId = Fixture.String();
                fixture.Setting.PrivatePairSettings.QueueSecret = Fixture.String();
                fixture.Setting.PrivatePairSettings.ClientId = accountId;
                fixture.Setting.PrivatePairSettings.ClientSecret = accountSecret;
                fixture.Setting.PrivatePairSettings.ValidEnvironment = Fixture.String();
                fixture.Setting.PrivatePairSettings.Services.Add(serviceId, new ServiceCredentials());
                fixture.Setting.ValidEnvironment = Fixture.String();

                await fixture.Subject.DecommissionCrawlerService(serviceId);

                fixture.Client
                       .DidNotReceiveWithAnyArgs()
                       .Delete(null, null)
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.Settings
                       .Received(1)
                       .Save(Arg.Is<InnographyPrivatePairSetting>(x => !x.PrivatePairSettings.Services.ContainsKey(serviceId))).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnIfServiceNotExist()
            {
                var fixture = new PrivatePairServiceFixture();

                await fixture.Subject.DecommissionCrawlerService(Fixture.String());

                fixture.Client
                       .DidNotReceive()
                       .Delete(Arg.Any<InnographyClientSettings>(), Arg.Any<Uri>())
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }
}