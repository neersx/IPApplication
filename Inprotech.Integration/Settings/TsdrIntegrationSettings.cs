using Inprotech.Contracts;

namespace Inprotech.Integration.Settings
{
    public interface ITsdrIntegrationSettings
    {
        string Key { get; set; }
    }

    public class TsdrIntegrationSettings : ITsdrIntegrationSettings
    {
        readonly GroupedConfigSettings _groupedConfigSettings;
        readonly ICryptoService _cryptoService;
        const string SettingsGroup = "TsdrIntegration";
        const string ApiKey = "ApiKey";
        
        string _key;

        public TsdrIntegrationSettings(GroupedConfigSettings.Factory groupedSettingsResolver, ICryptoService cryptoService)
        {
            _groupedConfigSettings = groupedSettingsResolver(SettingsGroup);
            _cryptoService = cryptoService;
        }

        public string Key
        {
            get => _key ?? (_key = GetKey());
            set
            {
                SetKey(value);
                _key = value;
            }
        }

        public void RefreshKeys()
        {
            _key = GetKey();
        }

        string GetKey()
        {
            var encryptedKey = _groupedConfigSettings[ApiKey];
            return string.IsNullOrWhiteSpace(encryptedKey) ? null : _cryptoService.Decrypt(encryptedKey);
        }

        void SetKey(string key)
        {
            _groupedConfigSettings[ApiKey] = _cryptoService.Encrypt(key);
        }
    }

    public class TsdrSecret
    {
        public TsdrSecret(string apiKey = null)
        {
            ApiKey = apiKey;
        }

        public string ApiKey { get; set; }
    }
}