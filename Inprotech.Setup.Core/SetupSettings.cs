using System;

namespace Inprotech.Setup.Core
{
    public class SetupSettings
    {
        public SetupStatus? Status { get; internal set; }
        public SetupRunMode RunMode { get; internal set; }
        public Version Version { get; internal set; }
        public string IisSite { get; internal set; }
        public string IisPath { get; internal set; }
        public string StorageLocation { get; internal set; }
        public string AuthenticationMode { get; internal set; }
        public string Authentication2FAMode { get; internal set; }
        public string DatabaseUsername { get; internal set; }
        public string DatabasePassword { get; internal set; }
        public string NewInstancePath { get; internal set; }
        public string CookieName { get; internal set; }
        public string CookiePath { get; internal set; }
        public string CookieDomain { get; internal set; }
        public CookieConsentSettings CookieConsentSettings { get; internal set; }
        public UsageStatisticsSettings UsageStatisticsSettings{ get; internal set; }
        public IpPlatformSettings IpPlatformSettings { get; internal set; }
        public AdfsSettings AdfsSettings { get; internal set; }
        public string IntegrationServerPort { get; internal set; }
        public string RemoteIntegrationServerUrl { get; internal set; }
        public string RemoteStorageServiceUrl { get; internal set; }
        public string IisAppInfoProfiles { get; set; }
        public bool IsE2EMode { get; set; }
        public bool BypassSslCertificateCheck { get; set; }
    }
}