using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Newtonsoft.Json;

namespace Inprotech.Web.Security
{
    public interface IAdfsSettingsResolver
    {
        AdfsSettings Resolve();
    }

    class AdfsSettingsResolver : IAdfsSettingsResolver
    {
        readonly ICryptoService _cryptoService;
        readonly IConfigSettings _settings;
        const string ConfigPrefix = "InprotechServer.Adfs";
        const string AdfsUrlKey = "Server";
        const string ClientIdKey = "ClientId";
        const string RelyingPartyAddressKey = "RelyingParty";
        const string CertificateStringKey = "Certificate";
        const string RedirectUrls = "RedirectUrls";

        public AdfsSettingsResolver(Func<string, IGroupedConfig> groupedConfig, ICryptoService cryptoService)
        {
            _cryptoService = cryptoService;
            _settings = groupedConfig(ConfigPrefix);
        }

        public AdfsSettings Resolve()
        {
            var configs = _settings.GetValues(AdfsUrlKey, ClientIdKey, RelyingPartyAddressKey, CertificateStringKey, RedirectUrls);
            return Decrypt(configs);
        }

        AdfsSettings Decrypt(Dictionary<string, string> configs)
        {
            return new AdfsSettings(configs[AdfsUrlKey], _cryptoService.Decrypt(configs[ClientIdKey]), _cryptoService.Decrypt(configs[RelyingPartyAddressKey]), _cryptoService.Decrypt(configs[CertificateStringKey]), configs[RedirectUrls]);
        }
    }

    public class AdfsSettings
    {
        public AdfsSettings(string adfsUrl, string clientId, string relyingPartyAddress, string certificate, string redirectUrls)
        {
            AdfsUrl = adfsUrl;
            ClientId = clientId;
            RelyingPartyAddress = relyingPartyAddress;
            Certificate = certificate;
            RedirectUrls = JsonConvert.DeserializeObject<Dictionary<string, string>>(redirectUrls).Select(_ => _.Value).ToList();
        }

        public string AdfsUrl { get; }
        public string ClientId { get; }
        public string RelyingPartyAddress { get; }
        public string Certificate { get; }
        public List<string> RedirectUrls { get; }
    }
}