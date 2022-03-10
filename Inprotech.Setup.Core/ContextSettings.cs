
namespace Inprotech.Setup.Core
{
    public class ContextSettings
    {
        public string StorageLocation { get; set; }

        public string PrivateKey { get; set; }

        public string IntegrationServerPort { get; set; }

        public string RemoteIntegrationServerUrl { get; set; }

        public string RemoteStorageServiceUrl { get; set; }

        public CookieConsentSettings CookieConsentSettings { get; set; }
        public UsageStatisticsSettings UsageStatisticsSettings{ get; set; }

        public string IisAppInfoProfiles { get; set; }

        public bool IsE2EMode { get; set; }

        public bool BypassSslCertificateCheck { get; set; }
    }
}
