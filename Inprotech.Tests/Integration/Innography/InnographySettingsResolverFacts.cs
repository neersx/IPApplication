using System;
using System.Collections.Generic;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Caching;
using Inprotech.Integration.Innography;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Innography
{
    public class InnographySettingsResolverFacts : FactBase
    {
        public InnographySettingsResolverFacts()
        {
            _cryptoService.Decrypt(Arg.Any<string>()).Returns(x => x[0]);
        }

        readonly IGroupedConfig _appSettings = Substitute.For<IGroupedConfig>();
        readonly ICryptoService _cryptoService = Substitute.For<ICryptoService>();
        readonly ILifetimeScopeCache _cache = Substitute.For<ILifetimeScopeCache>();

        InnographySettingsResolver CreateSubject()
        {
            _cache.GetOrAdd(
                            Arg.Any<InnographySettingsResolver>(),
                            Arg.Any<Type>(),
                            Arg.Any<Func<Type, InnographySetting>>())
                  .Returns(x => ((Func<Type, InnographySetting>) x[2])((Type) x[1]));

            return new InnographySettingsResolver(Db, Factory, _cryptoService, _cache);
        }

        IGroupedConfig Factory(string any)
        {
            return _appSettings;
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

        [Fact]
        public void ReturnsDetailsWhenSsoIsEnabled()
        {
            var settings = SetupCreds();
            var cypherText = JsonConvert.SerializeObject(settings);

            new ExternalSettings("Innography")
            {
                Settings = cypherText
            }.In(Db);

            _appSettings.GetValues("AuthenticationMode", "cpa.sso.clientId")
                        .Returns(new Dictionary<string, string>
                        {
                            {"AuthenticationMode", "Sso"},
                            {"cpa.sso.clientId", "inprotech"}
                        });

            var r = CreateSubject().Resolve(InnographyEndpoints.Default);

            Assert.True(r.IsIPIDIntegrationEnabled);
            Assert.Equal("inprotech", r.PlatformClientId);
            Assert.Equal("innography_user_name", r.ClientId);
            Assert.Equal("secret", r.ClientSecret);

            _cryptoService.Received(1).Decrypt(cypherText);
        }

        [Fact]
        public void ReturnsDisabledWhenSsoDisabled()
        {
            _appSettings.GetValues("AuthenticationMode", "cpa.sso.clientId")
                        .Returns(new Dictionary<string, string>
                        {
                            {"AuthenticationMode", "Forms,Windows"}
                        });

            var settings = SetupCreds();

            new ExternalSettings("Innography")
            {
                Settings = JsonConvert.SerializeObject(settings)
            }.In(Db);

            var r = CreateSubject().Resolve(InnographyEndpoints.Default);

            Assert.False(r.IsIPIDIntegrationEnabled);
        }

        [Fact]
        public void ReturnsUnencryptedPlatformId()
        {
            var encyptedPlatformId = Fixture.String();

            var settings = SetupCreds();

            new ExternalSettings("Innography")
            {
                Settings = JsonConvert.SerializeObject(settings)
            }.In(Db);

            _appSettings.GetValues("AuthenticationMode", "cpa.sso.clientId")
                        .Returns(new Dictionary<string, string>
                        {
                            {"AuthenticationMode", "Sso"},
                            {"cpa.sso.clientId", encyptedPlatformId}
                        });

            _cryptoService.Decrypt(encyptedPlatformId)
                          .Returns("inprotech");

            var r = CreateSubject().Resolve(InnographyEndpoints.Default);

            Assert.True(r.IsIPIDIntegrationEnabled);
            Assert.Equal("inprotech", r.PlatformClientId);
        }

        [Fact]
        public void ThrowsExceptionIfRequiredKeysNotAvailable()
        {
            _appSettings.GetValues("AuthenticationMode", "cpa.sso.clientId")
                        .Returns(new Dictionary<string, string>
                        {
                            {"AuthenticationMode", "Forms,Windows"}
                        });

            var settings = SetupCreds();

            new ExternalSettings("Innography")
            {
                Settings = JsonConvert.SerializeObject(settings)
            }.In(Db);
            var r = CreateSubject().Resolve(InnographyEndpoints.Default);

            Assert.Throws<Exception>(() => r.EnsureRequiredKeysAvailable());
        }
    }
}