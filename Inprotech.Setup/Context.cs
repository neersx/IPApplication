using System;
using Inprotech.Setup.Core;

namespace Inprotech.Setup
{
    //todo: convert to interface
    public static class Context
    {
        static Context()
        {
            AuthenticationSettings = new AuthenticationSettings();
            CookieConsentSettings = new CookieConsentSettings();
            UsageStatisticsSettings = new UsageStatisticsSettings();
        }

        public static SetupRunMode RunMode { get; set; }

        public static IisAppInfo SelectedIisApp { get; set; }

        public static WebAppInfoWrapper SelectedWebApp { get; set; }

        public static string PrivateKey { get; set; }

        public static string StorageLocation { get; set; }

        public static string IntegrationServerPort { get; set; }

        public static Uri RemoteIntegrationServerUrl { get; set; }

        public static Uri RemoteStorageServiceUrl { get; set; }

        public static CookieConsentSettings CookieConsentSettings { get; set; }
        public static UsageStatisticsSettings UsageStatisticsSettings { get; set; }

        public static AuthenticationSettings AuthenticationSettings { get; set; }

        public static string IisAppInfoProfiles { get; set; }

        public static void Reset()
        {
            IisAppInfoProfiles = null;
            SelectedIisApp = null;
            SelectedWebApp = null;
            StorageLocation = null;
            IntegrationServerPort = null;
            RemoteIntegrationServerUrl = null;
            RemoteStorageServiceUrl = null;
            PrivateKey = null;
            AuthenticationSettings.Reset();
            CookieConsentSettings.Reset();
            UsageStatisticsSettings.Reset();
        }

        public static IisAppInfo ResolvedIisApp => RunMode == SetupRunMode.New ? SelectedIisApp : SelectedWebApp.PairedIisAppInfo;

        public static void SetAuthMode(string authMode)
        {
            if (AuthenticationSettings == null)
                AuthenticationSettings = new AuthenticationSettings();
            AuthenticationSettings.AuthenticationMode = authMode;
        }

        public static void Set2FAMode(string authMode)
        {
            if (AuthenticationSettings == null)
                AuthenticationSettings = new AuthenticationSettings();
            AuthenticationSettings.TwoFactorAuthenticationMode = authMode;
        }

        public static ContextSettings GetContextSettings()
        {
            return new ContextSettings
            {
                StorageLocation = StorageLocation,
                PrivateKey = PrivateKey,
                IntegrationServerPort = IntegrationServerPort,
                RemoteIntegrationServerUrl = RemoteIntegrationServerUrl?.ToString(),
                RemoteStorageServiceUrl = RemoteStorageServiceUrl?.ToString(),
                CookieConsentSettings = CookieConsentSettings,
                UsageStatisticsSettings = UsageStatisticsSettings,
                IisAppInfoProfiles = IisAppInfoProfiles
            };
        }
    }
}