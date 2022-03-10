using System;
using System.Collections.Generic;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Innography.Ids
{
    public interface IPatentScoutSettingsResolver
    {
        InnographySetting Resolve();
    }
    public class PatentScoutSettingsResolver : BaseInnographySettingsResolver, IPatentScoutSettingsResolver
    {
        public InnographySetting Resolve()
        {
            return _cache.GetOrAdd(this, typeof(PatentScoutSettingsResolver), x => ResolveImmediate());
        }
        
        public InnographySetting ResolveImmediate()
        {
            var values = _config.GetValues(
                                           KnownAppSettingsKeys.AuthenticationMode,
                                           KnownAppSettingsKeys.CpaSsoClientId);

            var configuredAuthMode = new ConfiguredAuthMode(values[KnownAppSettingsKeys.AuthenticationMode]);

            var settings = GetEncryptedExternalSettings<CredentialsMap>("Innography");
            var overrideSettings = GetExternalSettings<Dictionary<string, string>>("InnographyOverrides");

            if (values.TryGetValue(KnownAppSettingsKeys.CpaSsoClientId, out var platformClientId)
                && !string.IsNullOrWhiteSpace(platformClientId))
            {
                platformClientId = _cryptoService.Decrypt(platformClientId);
            }

            var result = new InnographySetting
            {
                IsIPIDIntegrationEnabled = configuredAuthMode.SsoEnabled,
                PlatformClientId = platformClientId,
                ApiBase = new Uri("https://ps.innography.com")
            };

            var clientCredentials = settings.Resolve(InnographyEndpoints.PatentScout);
            result.ClientId = clientCredentials?.ClientId;
            result.ClientSecret = clientCredentials?.ClientSecret;

            AugmentOrOverrideSettings(result, overrideSettings, InnographyEndpoints.PatentScout);

            return result;
        }

        public PatentScoutSettingsResolver(IDbContext dbContext, Func<string, IGroupedConfig> groupedConfig, ICryptoService cryptoService, ILifetimeScopeCache cache) : base(dbContext, groupedConfig, cryptoService, cache)
        {
        }
    }
}
