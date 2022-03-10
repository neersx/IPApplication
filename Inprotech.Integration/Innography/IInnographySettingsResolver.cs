using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography
{
    public interface IInnographySettingsResolver
    {
        InnographySetting Resolve(string endpoint);
    }

    public sealed class InnographySettingsResolver : BaseInnographySettingsResolver, IInnographySettingsResolver
    {
        public InnographySettingsResolver(IDbContext dbContext, Func<string, IGroupedConfig> groupedConfig, ICryptoService cryptoService, ILifetimeScopeCache cache)
            : base(dbContext, groupedConfig, cryptoService, cache)
        {
        }

        public InnographySetting Resolve(string endpoint)
        {
            return Resolve<InnographySetting>(endpoint);
        }
    }

    public class BaseInnographySettingsResolver
    {
        public readonly ILifetimeScopeCache _cache;
        public readonly IGroupedConfig _config;
        public readonly ICryptoService _cryptoService;
        readonly IDbContext _dbContext;

        ExternalSettings[] _innographySettings;

        protected BaseInnographySettingsResolver(IDbContext dbContext, Func<string, IGroupedConfig> groupedConfig, ICryptoService cryptoService, ILifetimeScopeCache cache)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
            _cache = cache;
            _config = groupedConfig("InprotechServer.AppSettings");
        }

        protected T Resolve<T>(string endpoint) where T : InnographySetting, new()
        {
            return _cache.GetOrAdd(this, typeof(T), x => ResolveImmediate<T>(endpoint));
        }

        protected bool UpdateCache<T>(T updatedValue, T comparisonValue) where T : InnographySetting, new()
        {
            return _cache.Update(this, typeof(T), updatedValue, comparisonValue);
        }

        protected T ResolveImmediate<T>(string endpoint) where T : InnographySetting, new()
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

            var result = new T
            {
                IsIPIDIntegrationEnabled = configuredAuthMode.SsoEnabled,
                PlatformClientId = platformClientId,
                ApiBase = ResolveApiBase(endpoint)
            };

            var clientCredentials = settings.Resolve(endpoint);
            result.ClientId = clientCredentials?.ClientId;
            result.ClientSecret = clientCredentials?.ClientSecret;

            AugmentOrOverrideSettings(result, overrideSettings, endpoint);

            return result;
        }

        protected virtual void AugmentOrOverrideSettings(object current, IReadOnlyDictionary<string, string> overrideSettings = null, string endpoint = "")
        {
            if (overrideSettings == null) return;

            var setting = (InnographySetting) current;

            if (overrideSettings.TryGetValue(endpoint, out var apiBase))
            {
                setting.ApiBase = new Uri(apiBase);
            }
        }

        protected T GetExternalSettings<T>(string providerName)
        {
            var setting = GetExternalSettingsClearText(providerName, false);
            
            return string.IsNullOrWhiteSpace(setting) 
                ? default(T) 
                : JsonConvert.DeserializeObject<T>(setting);
        }
        
        protected T GetEncryptedExternalSettings<T>(string providerName)
        {
            var setting = GetExternalSettingsClearText(providerName, true);

            return string.IsNullOrWhiteSpace(setting) 
                ? default(T) 
                : JsonConvert.DeserializeObject<T>(setting);
        }

        string GetExternalSettingsClearText(string providerName, bool decrypt)
        {
            if (_innographySettings == null)
            {
                _innographySettings = _dbContext.Set<ExternalSettings>()
                                                .Where(_ => _.ProviderName.StartsWith("Innography"))
                                                .ToArray();
            }

            var setting = _innographySettings.SingleOrDefault(_ => _.ProviderName == providerName)?.Settings;

            return decrypt && !string.IsNullOrWhiteSpace(setting)
                ? _cryptoService.Decrypt(setting)
                : setting;
        }

        Uri ResolveApiBase(string endpoint)
        {
            switch (endpoint)
            {
                case InnographyEndpoints.TrademarksDv:
                    return new Uri("https://tm.innography.com/");
                case InnographyEndpoints.PatentScout:
                    return new Uri("https://ps.innography.com");
                default:
                    return new Uri("https://api.innography.com/");
            }
        }
    }

    public class InnographySetting
    {
        public bool IsIPIDIntegrationEnabled { get; set; }

        public string PlatformClientId { get; set; }

        public string ClientId { get; set; }

        public string ClientSecret { get; set; }

        public Uri ApiBase { get; set; }

        public void EnsureRequiredKeysAvailable(string forSystem = "IP One Data")
        {
            if (IsIPIDIntegrationEnabled) return;

            throw new Exception($"{forSystem} connectivity requires the Firm to have already configured for The IP Platform access.");
        }
    }

    public class InnographyClientCredentials
    {
        public string CryptoAlgorithm { get; set; }
        public string ClientId { get; set; }
        public string ClientSecret { get; set; }
    }

    public class CredentialsMap
    {
        const string DefaultGateway = "api-gateway-1";
        public Dictionary<string, InnographyClientCredentials> Credentials { get; set; }
        public Dictionary<string, string> Endpoints { get; set; }

        public CredentialsMap()
        {
            Credentials = new Dictionary<string, InnographyClientCredentials>();
            Endpoints = new Dictionary<string, string>();
        }

        public InnographyClientCredentials Resolve(string endpoint)
        {  
            if (Endpoints.TryGetValue(endpoint, out var keyToCredentials)
                 && Credentials.TryGetValue(keyToCredentials, out var clientCreds))
            {
                return clientCreds;
            }

            Credentials.TryGetValue(DefaultGateway, out clientCreds);
            return clientCreds;
        }
    }

    public static class InnographyEndpoints
    {
        public const string PatentsDv = "dv";
        public const string TrademarksDv = "tm-dv";
        public const string Documents = "ids";
        public const string PatentScout = "ps";
        public const string Default = "";
    }

    public static class CryptoAlgorithm
    {
        public static readonly string Sha1 = "hmac-sha1";
        public static readonly string Sha256 = "hmac-sha256";
    }

    public static class InnographySettingsExt
    {
        public static void EnsureRequiredKeysAvailable(this IInnographySettingsResolver innographySettingsResolver)
        {
            var innographySettings = innographySettingsResolver.Resolve(InnographyEndpoints.Default);

            innographySettings.EnsureRequiredKeysAvailable("Innography");
        }
    }
}