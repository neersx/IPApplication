using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Hosting;
using InprotechKaizen.Model.Components.Names;

namespace Inprotech.Integration.GoogleAnalytics
{
    public interface IAnalyticsIdentifierResolver
    {
        Task<string> Resolve();
    }
    class AnalyticsIdentifierResolver : IAnalyticsIdentifierResolver
    {
        readonly ISiteControlReader _siteControlReader;
        readonly IDisplayFormattedName _displayFormattedName;
        readonly IConfigurationSettings _configurationSettings;
        readonly Func<HostInfo> _hostInfoResolver;

        public AnalyticsIdentifierResolver(ISiteControlReader siteControlReader,
                                                   IDisplayFormattedName displayFormattedName, IConfigurationSettings configurationSettings, Func<HostInfo> hostInfoResolver)
        {
            _siteControlReader = siteControlReader;
            _displayFormattedName = displayFormattedName;
            _configurationSettings = configurationSettings;
            _hostInfoResolver = hostInfoResolver;
        }

        public async Task<string> Resolve()
        {
            var homeNameNoSc = _siteControlReader.Read<int>(SiteControls.HomeNameNo);
            var homeNameNo = await _displayFormattedName.For(homeNameNoSc);
            var dbIdentifier = _hostInfoResolver().DbIdentifier;
            var encryptedBase64 = $"{Encrypt(homeNameNo)}.{Encrypt(dbIdentifier)}";
            var encoded = HttpUtility.UrlEncode(encryptedBase64);
            return encoded;
        }

        string Encrypt(string plainText)
        {
            var privateKey = _configurationSettings[KnownAppSettingsKeys.AnalyticsIdentifierPrivateKey];
            if (string.IsNullOrWhiteSpace(privateKey))
            {
                throw new ArgumentNullException($"Encyption key not supplied");
            }

            var privateKeyBytes = Encoding.ASCII.GetBytes(privateKey);
            using (var cryptoProvider = new AesCryptoServiceProvider())
            using (var memoryStream = new MemoryStream())
            using (
                var cryptoStream = new CryptoStream(
                                                    memoryStream,
                                                    cryptoProvider.CreateEncryptor(privateKeyBytes, privateKeyBytes),
                                                    CryptoStreamMode.Write))
            using (var writer = new StreamWriter(cryptoStream))
            {
                writer.Write(plainText);
                writer.Flush();
                cryptoStream.FlushFinalBlock();
                writer.Flush();
                return Convert.ToBase64String(memoryStream.GetBuffer(), 0, (int)memoryStream.Length);
            }
        }
    }
}