using Inprotech.Contracts;
using Newtonsoft.Json;

namespace Inprotech.Integration.Settings
{
    public interface IEpoIntegrationSettings
    {
        EpoKeys Keys { get; set; }
    }

    public class EpoIntegrationSettings : IEpoIntegrationSettings
    {
        readonly GroupedConfigSettings _groupedConfigSettings;
        readonly ICryptoService _cryptoService;
        const string SettingsGroup = "EpoIntegration";
        const string ConsumerKeyString = "ConsumerKeys";

        EpoKeys _keys;

        public EpoIntegrationSettings(GroupedConfigSettings.Factory groupedSettingsResolver, ICryptoService cryptoService)
        {
            _groupedConfigSettings = groupedSettingsResolver(SettingsGroup);
            _cryptoService = cryptoService;
        }

        public EpoKeys Keys
        {
            get => _keys ?? (_keys = GetKeys());
            set
            {
                SetKeys(value);
                _keys = value;
            }
        }

        public void RefreshKeys()
        {
            _keys = GetKeys();
        }

        EpoKeys GetKeys()
        {
            var encryptedKeys = _groupedConfigSettings[ConsumerKeyString];
            var decryptedKeys = string.IsNullOrWhiteSpace(encryptedKeys) ? null : _cryptoService.Decrypt(encryptedKeys);
            
            return string.IsNullOrWhiteSpace(decryptedKeys) ? new EpoKeys() : JsonConvert.DeserializeObject<EpoKeys>(decryptedKeys);
        }

        void SetKeys(EpoKeys keys)
        {
            _groupedConfigSettings[ConsumerKeyString] = _cryptoService.Encrypt(JsonConvert.SerializeObject(keys));
        }
    }

    public class EpoKeys
    {
        public EpoKeys(string consumerKey = null, string privateKey = null)
        {
            ConsumerKey = consumerKey;
            PrivateKey = privateKey;
        }

        public string ConsumerKey { get; set; }
        public string PrivateKey { get; set; }
    }
}