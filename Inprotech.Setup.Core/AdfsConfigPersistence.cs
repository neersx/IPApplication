using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Setup.Core.Utilities;
using Newtonsoft.Json;

namespace Inprotech.Setup.Core
{
    public interface IAdfsConfigPersistence
    {
        Task<AdfsSettings> GetAdfsSettings(string privateKey);
        Task SetAdfsSettings(string privateKey, AdfsSettings adfsSettings);
    }

    public class AdfsConfigPersistence : IAdfsConfigPersistence
    {
        readonly string _connectionString;
        readonly IPersistingConfigManager _persistingConfigManager;
        readonly ICryptoService _cryptoService;
        const string ConfigPrefix = "InprotechServer.Adfs";
        const string AdfsUrlKey = "Server";
        const string ClientIdKey = "ClientId";
        const string RelyingPartyAddressKey = "RelyingParty";
        const string CertificateStringKey = "Certificate";
        const string RedirectUrls = "RedirectUrls";

        public AdfsConfigPersistence(string connectionString)
            : this(connectionString, new CryptoService(), new PersistingConfigManager(ConfigPrefix)) { }

        public AdfsConfigPersistence(string connectionString, ICryptoService cryptoService, IPersistingConfigManager persistingConfigManager)
        {
            _persistingConfigManager = persistingConfigManager;
            _connectionString = connectionString;
            _cryptoService = cryptoService;
        }

        public async Task<AdfsSettings> GetAdfsSettings(string privateKey)
        {
            var adfsSettings = new AdfsSettings();
            var values = await _persistingConfigManager.GetValues(_connectionString, AdfsUrlKey, ClientIdKey, RelyingPartyAddressKey, CertificateStringKey, RedirectUrls);

            adfsSettings.ServerUrl = values.ContainsKey(AdfsUrlKey) ? values[AdfsUrlKey] : null;
            adfsSettings.ClientId = values.ContainsKey(ClientIdKey) ? values[ClientIdKey] : null;
            adfsSettings.RelyingPartyTrustId = values.ContainsKey(RelyingPartyAddressKey) ? values[RelyingPartyAddressKey] : null;
            adfsSettings.Certificate = values.ContainsKey(CertificateStringKey) ? values[CertificateStringKey] : null;
            adfsSettings.ReturnUrls = values.ContainsKey(RedirectUrls) ? JsonConvert.DeserializeObject<Dictionary<string, string>>(values[RedirectUrls]) : new Dictionary<string, string>();
            try
            {
                _cryptoService.Decrypt(privateKey, adfsSettings);
            }
            catch
            {
                //ignore
            }

            return adfsSettings;
        }

        public async Task SetAdfsSettings(string privateKey, AdfsSettings adfsSettings)
        {
            var adfsSettingEncrypt = adfsSettings.Copy();
            _cryptoService.Encrypt(privateKey, adfsSettingEncrypt);

            var values = new Dictionary<string, string>
            {
                {AdfsUrlKey, adfsSettingEncrypt.ServerUrl},
                {ClientIdKey, adfsSettingEncrypt.ClientId},
                {RelyingPartyAddressKey, adfsSettingEncrypt.RelyingPartyTrustId},
                {CertificateStringKey, adfsSettingEncrypt.Certificate},
                {RedirectUrls, JsonConvert.SerializeObject(adfsSettingEncrypt.ReturnUrls)}
            };

            await _persistingConfigManager.SetValues(_connectionString, values);
        }
    }
}