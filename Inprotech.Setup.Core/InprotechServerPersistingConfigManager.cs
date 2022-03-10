using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Setup.Core.Annotations;
using Inprotech.Setup.Core.Utilities;
using Newtonsoft.Json;

namespace Inprotech.Setup.Core
{
    public interface IInprotechServerPersistingConfigManager
    {
        Task<IpPlatformSettings> GetIpPlatformSettings(string connectionString, string privateKey);

        Task<InstanceDetails> GetPersistedInstanceDetails(string connectionString);

        Task SetPersistedInstanceDetails(string connectionString, InstanceDetails instanceDetails);

        Task SetIpPlatformSettings(string connectionString, string privateKey, IpPlatformSettings ipPlatformSettings);

        Task SaveAuthMode(string connectionString, string authModes);

        Task Save2FAAuthMode(string connectionString, string authModes);

        Task RemovePrivateKey(string connectionString);

        Task<Dictionary<string, string>> GetSetupDetails(string connectionString);

        Task SetSetupValues(string connectionString, Dictionary<string, string> data);
        Task SaveProductImprovement(string connectionString, string settings);
        Task<UsageStatisticsSettings> GetProductImprovement(string connectionString);
    }

    public class InprotechServerPersistingConfigManager : IInprotechServerPersistingConfigManager
    {
        readonly string _2FAAuthenticationMode = "Authentication2FAMode";
        readonly IPersistingConfigManager _appSettings;
        readonly string _appSettingsGroup = "InprotechServer.AppSettings";

        readonly string _authenticationMode = "AuthenticationMode";
        readonly ICryptoService _cryptoService;
        readonly string _privateKey = "PrivateKey";
        readonly string _productImprovement = "ProductImprovement";
        readonly IPersistingConfigManager _unscoped;

        public InprotechServerPersistingConfigManager()
        {
            _appSettings = new PersistingConfigManager(_appSettingsGroup);
            _unscoped = new PersistingConfigManager(null);

            _cryptoService = new CryptoService();
        }

        public async Task<IpPlatformSettings> GetIpPlatformSettings(string connectionString, string privateKey)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                return new IpPlatformSettings();
            }

            var ipPlatformSettings = new IpPlatformSettings();
            var values = await _appSettings.GetValues(connectionString, Constants.IpPlatformSettings.ClientId, Constants.IpPlatformSettings.ClientSecret);

            ipPlatformSettings.ClientId = values.ContainsKey(Constants.IpPlatformSettings.ClientId) ? values[Constants.IpPlatformSettings.ClientId] : null;
            ipPlatformSettings.ClientSecret = values.ContainsKey(Constants.IpPlatformSettings.ClientSecret) ? values[Constants.IpPlatformSettings.ClientSecret] : null;

            try
            {
                _cryptoService.Decrypt(privateKey, ipPlatformSettings);
            }
            catch
            {
                //ignore
            }

            return ipPlatformSettings;
        }

        public async Task<InstanceDetails> GetPersistedInstanceDetails(string connectionString)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                return new InstanceDetails();
            }

            var values = await _unscoped.GetValues(connectionString, Constants.InprotechServer.Instances, Constants.IntegrationServer.Instances);

            var inprotechServerInstances = values.ContainsKey(Constants.InprotechServer.Instances) ? values[Constants.InprotechServer.Instances] : null;

            var inprotechIntegrationServerInstances = values.ContainsKey(Constants.IntegrationServer.Instances) ? values[Constants.IntegrationServer.Instances] : null;

            return new InstanceDetails(inprotechServerInstances, inprotechIntegrationServerInstances);
        }

        public async Task<Dictionary<string, string>> GetSetupDetails(string connectionString)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                return new Dictionary<string, string>();
            }

            var values = await _unscoped.GetValues(connectionString, Constants.InprotechServer.Setup);

            return values.ContainsKey(Constants.InprotechServer.Setup)
                ? JsonConvert.DeserializeObject<Dictionary<string, string>>(values[Constants.InprotechServer.Setup])
                : new Dictionary<string, string>();
        }

        public async Task SetSetupValues(string connectionString, Dictionary<string, string> data)
        {
            var existing = await GetSetupDetails(connectionString);

            foreach (var modified in data.Keys) existing[modified] = data[modified];

            await _unscoped.SetValues(connectionString,
                                      new Dictionary<string, string>
                                      {
                                          {Constants.InprotechServer.Setup, JsonConvert.SerializeObject(existing)}
                                      });
        }

        public async Task SaveProductImprovement(string connectionString, string settings)
        {
            var values = new Dictionary<string, string>
            {
                {_productImprovement, settings}
            };

            await _appSettings.SetValues(connectionString, values);
        }

        public async Task<UsageStatisticsSettings> GetProductImprovement(string connectionString)
        {
            var setting = await _appSettings.GetValues(connectionString, _productImprovement);
            if (setting.ContainsKey(_productImprovement))
            {
                return JsonConvert.DeserializeObject<UsageStatisticsSettings>(setting[_productImprovement]);
            }

            return new UsageStatisticsSettings();
        }

        public async Task SetPersistedInstanceDetails([NotNull] string connectionString, [NotNull] InstanceDetails instanceDetails)
        {
            if (connectionString == null) throw new ArgumentNullException(nameof(connectionString));
            if (instanceDetails == null) throw new ArgumentNullException(nameof(instanceDetails));

            await _unscoped.SetValues(connectionString,
                                      new Dictionary<string, string>
                                      {
                                          {Constants.InprotechServer.Instances, instanceDetails.InprotechServer.AsJson()},
                                          {Constants.IntegrationServer.Instances, instanceDetails.IntegrationServer.AsJson()}
                                      });
        }

        public async Task SetIpPlatformSettings(string connectionString, string privateKey, IpPlatformSettings ipPlatformSettings)
        {
            var ipPlatformSettingsEncrypted = ipPlatformSettings.Copy();

            _cryptoService.Encrypt(privateKey, ipPlatformSettingsEncrypted);

            var values = new Dictionary<string, string>
            {
                {Constants.IpPlatformSettings.ClientId, ipPlatformSettingsEncrypted.ClientId},
                {Constants.IpPlatformSettings.ClientSecret, ipPlatformSettingsEncrypted.ClientSecret}
            };

            await _appSettings.SetValues(connectionString, values);
        }

        public async Task SaveAuthMode(string connectionString, string authModes)
        {
            var values = new Dictionary<string, string>
            {
                {_authenticationMode, authModes}
            };

            await _appSettings.SetValues(connectionString, values);
        }

        public async Task Save2FAAuthMode(string connectionString, string authModes)
        {
            var values = new Dictionary<string, string>
            {
                {_2FAAuthenticationMode, authModes}
            };

            await _appSettings.SetValues(connectionString, values);
        }

        public async Task RemovePrivateKey(string connectionString)
        {
            await _appSettings.RemoveConfig(connectionString, _privateKey);
        }
    }
}