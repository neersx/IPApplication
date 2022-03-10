using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Caching;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public interface IInnographyPrivatePairSettings
    {
        InnographyPrivatePairSetting Resolve();

        Task Save(InnographyPrivatePairSetting settings);
    }

    public sealed class InnographyPrivatePairSettings : BaseInnographySettingsResolver, IInnographyPrivatePairSettings
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly IInnographySettingsPersister _settingsPersister;

        public InnographyPrivatePairSettings(IDbContext dbContext,
                                             Func<string, IGroupedConfig> groupedConfig,
                                             ICryptoService cryptoService,
                                             IAppSettingsProvider appSettingsProvider,
                                             IInnographySettingsPersister settingsPersister,
                                             ILifetimeScopeCache cache)
            : base(dbContext, groupedConfig, cryptoService, cache)
        {
            _appSettingsProvider = appSettingsProvider;
            _settingsPersister = settingsPersister;
        }

        public InnographyPrivatePairSetting Resolve()
        {
            return Resolve<InnographyPrivatePairSetting>(InnographyEndpoints.Default);
        }

        public async Task Save(InnographyPrivatePairSetting settings)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            var current = Resolve();

            await _settingsPersister.SecureAddOrUpdate("InnographyPrivatePair", settings.PrivatePairSettings);

            current.PrivatePairSettings = settings.PrivatePairSettings;

            UpdateCache(current, current);
        }

        protected override void AugmentOrOverrideSettings(object current, IReadOnlyDictionary<string, string> overrideSettings = null, string endpoint = "")
        {
            if (current == null) throw new ArgumentNullException(nameof(current));

            base.AugmentOrOverrideSettings(current, overrideSettings, endpoint);

            var setting = (InnographyPrivatePairSetting)current;

            setting.PrivatePairSettings = GetEncryptedExternalSettings<PrivatePairExternalSettings>("InnographyPrivatePair") ?? new PrivatePairExternalSettings();
            setting.ValidEnvironment = setting.PrivatePairSettings.ValidEnvironment;

            if (overrideSettings != null)
            { 
                if (overrideSettings.TryGetValue("pp", out var ppApiBase))
                {
                    setting.PrivatePairApiBase = new Uri(ppApiBase);
                }

                if (overrideSettings.TryGetValue("pp-env", out string ppEnvs))
                {
                    setting.ValidEnvironment = ppEnvs;
                }
            }

            var pp = _appSettingsProvider["InnographyOverrides:pp"];
            if (!string.IsNullOrWhiteSpace(pp))
            {
                setting.PrivatePairApiBase = new Uri(pp);
            }
        }
    }

    public class InnographyPrivatePairSetting : InnographySetting
    {
        public PrivatePairExternalSettings PrivatePairSettings { get; set; }

        public string ValidEnvironment { get; set; }

        public Uri PrivatePairApiBase { get; internal set; } = new Uri("https://api.innography.com/");
    }

    public class PrivatePairExternalSettings
    {
        public PrivatePairExternalSettings()
        {
            Services = new Dictionary<string, ServiceCredentials>();
        }

        public string ClientId { get; set; }

        public string ClientSecret { get; set; }

        public string QueueId { get; set; }

        public string QueueSecret { get; set; }

        public string QueueUrl { get; set; }

        public string SqsRegion { get; set; }

        public string ValidEnvironment { get; set; }

        public Dictionary<string, ServiceCredentials> Services { get; set; }

        public bool IsAccountSettingsValid =>
            !string.IsNullOrWhiteSpace(ClientId) &&
            !string.IsNullOrWhiteSpace(ClientSecret) &&
            !string.IsNullOrWhiteSpace(QueueId) &&
            !string.IsNullOrWhiteSpace(QueueSecret);
    }

    public class ServiceCredentials
    {
        public string Id { get; set; }

        public string SponsoredEmail { get; set; }

        public string SponsorName { get; set; }

        public KeySet KeySet { get; set; }
    }
}