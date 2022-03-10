namespace Inprotech.Setup.Core
{
    public static class Constants
    {
        public const string DefaultRootPath = ".\\instances";
        public const string ContentRoot = "content";
        public const string SettingsFileName = "settings.json";
        public const string SetupActionsFileName = "Inprotech.Setup.Actions.dll";
        public const string BackupDirectory = ".backup";
        public const string WorkingDirectory = ".workdir";
        public const string BinFolder = "bin";
        public const string InprotechCoreDll = "Inprotech.Core.dll";
        public const string DefaultStorageLocation = @"C:\Inprotech\Storage";
        public const string UtilityFolder = "Utility";
        public static readonly string[] ExcludedEncryptedSettings = { "cpa.sso.*", "cpa.iam.*", "PrivateKey", "LegacyPrivateKey", "EncryptionKey", "CertificateAuthenticatorKey", "Hide AppSettings", "AnalyticsIdentifierPrivateKey" };

        public static class AuthenticationModeKeys
        {
            public const string Forms = "Forms";
            public const string Windows = "Windows";
            public const string Sso = "Sso";
            public const string Adfs = "Adfs";
        }

        public static class Authentication2FAModeKeys
        {
            public const string Internal = "Internal";
            public const string External = "External";
        }
        
        public static class IpPlatformSettings
        {
            public const string Prefix = "cpa.sso.";
            public const string IamProxyPrefix = "cpa.iam.proxy.";
            public const string ClientId = Prefix + "clientId";
            public const string ClientSecret = Prefix + "clientSecret";
            public const string TesterUtilityPath = UtilityFolder + @"\ConnectivityTest\IpPlatformTester.exe";
        }

        public static class MigrateIWSConfigSettings
        {
            public const string MigrateUtilityPath = UtilityFolder + @"\IWSConfig\IWSConfig.exe";
        }

        public static class InprotechServer
        {
            public const string Folder = "Inprotech.Server";
            public const string Exe = Folder + ".exe";
            public const string Instances = Folder + ".Instances";
            public const string Setup = Folder + ".Setup";
            public const string TranslationFolder = Folder + @"\client\condor\localisation\translations";
            public const string ConfigPath = Folder + @"\inprotech.server.exe.config";
            public const string ClientRoot = Folder + @"\client";

            public static class SetupConfiguration
            {
                public const string CookieConsentBannerHook = "CookieConsentBannerHook";
                public const string CookieDeclarationHook = "CookieDeclarationHook";
                public const string CookieResetConsentHook = "CookieResetConsentHook";
                public const string CookieConsentVerificationHook = "CookieConsentVerificationHook";
                public const string PreferenceConsentVerificationHook = "PreferenceConsentVerificationHook";
                public const string StatisticsConsentVerificationHook = "StatisticsConsentVerificationHook";
                public const string FirmUsageStatisticsConsented = "FirmUsageStatisticsConsented";
                public const string UserUsageStatisticsConsented = "UserUsageStatisticsConsented";
            }
        }

        public static class IntegrationServer
        {
            public const string Folder = "Inprotech.IntegrationServer";
            public const string Exe = Folder + ".exe";
            public const string Instances = Folder + ".Instances";
        }

        public static class StorageService
        {
            public const string Folder = "Inprotech.StorageService";
            public const string Exe = Folder + ".exe";
            public const string Config = Exe + ".config";
            public const string Instances = Folder + ".Instances";
        }

        public static class InprotechBackup
        {
            public const string Folder = "backup";
            public const string WebConfig = "web.config.sav";
        }

        public static class Branding
        {
            public const string BatchEventCustomStylesheet = InprotechServer.ClientRoot + @"\batchEventUpdate\custom.css";
            public const string CustomStylesheet = InprotechServer.ClientRoot + @"\styles\custom.css";
            public const string FavIcon = InprotechServer.ClientRoot + @"\favicon.ico";
            public const string ImagesFolder = InprotechServer.ClientRoot + @"\images";
        }

        public static class AppSettings
        {
            public static class InprotechServerSettings
            {
                public const string PrivateKey = "PrivateKey";
            }
        }
    }
}