using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.IO;

namespace Inprotech.Setup.Core
{
    [SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    public class SetupContext : Dictionary<string, object>
    {
        IisAppInfo _pairedIisApp;
        SetupSettings _setupSettings;

        public SetupContext()
        {
            Reset();
        }

        public string StorageLocation
        {
            get => Get<string>("StorageLocation");
            set => this["StorageLocation"] = value;
        }

        public string PrivateKey
        {
            get => Get<string>(nameof(PrivateKey));
            set => this[nameof(PrivateKey)] = value;
        }

        public string AuthenticationMode
        {
            get => Get<string>("AuthenticationMode");
            set => this["AuthenticationMode"] = value;
        }

        public string Authentication2FAMode
        {
            get => Get<string>("Authentication2FAMode");
            set => this["Authentication2FAMode"] = value;
        }

        public IpPlatformSettings IpPlatformSettings
        {
            get => Get<IpPlatformSettings>("IpPlatformSettings");
            set => this["IpPlatformSettings"] = value;
        }

        public AdfsSettings AdfsSettings
        {
            get => Get<AdfsSettings>("AdfsSettings");
            set => this["AdfsSettings"] = value;
        }

        public string InstancePath
        {
            get => Get<string>("InstanceDirectory");
            set
            {
                this["InstanceDirectory"] = value;
                this["InstanceName"] = Path.GetFileName(value);
            }
        }

        public string BackupDirectory
        {
            get => Get<string>("BackupDirectory");
            private set => this["BackupDirectory"] = value;
        }

        public string IisSite
        {
            get => Get<string>("Site");
            set => this["Site"] = value;
        }

        public string IisPath
        {
            get => Get<string>("VirtualPath");
            set => this["VirtualPath"] = value;
        }

        public string DatabaseUsername
        {
            get => Get<string>("Database.Username");
            set
            {
                if (!string.IsNullOrEmpty(value))
                {
                    this["Database.Username"] = value;
                }
            }
        }

        public string DatabasePassword
        {
            get => Get<string>("Database.Password");
            set
            {
                if (!string.IsNullOrEmpty(value))
                {
                    this["Database.Password"] = value;
                }
            }
        }

        public string RootPath { get; set; }

        public string NewRootPath { get; set; }

        public string NewInstancePath { get; set; }

        public string IntegrationServerPort
        {
            get => Get<string>("IntegrationServer.Port");
            set => this["IntegrationServer.Port"] = value;
        }

        public string RemoteIntegrationServerUrl
        {
            get => Get<string>("RemoteIntegrationServerUrl");
            set => this["RemoteIntegrationServerUrl"] = value;
        } 

        public string RemoteStorageServiceUrl
        {
            get => Get<string>("RemoteStorageServiceUrl");
            set => this["RemoteStorageServiceUrl"] = value;
        }

        public string CookieName
        {
            get => Get<string>("SessionCookieName");
            set => this["SessionCookieName"] = value;
        }

        public string CookiePath
        {
            get => Get<string>("SessionCookiePath");
            set => this["SessionCookiePath"] = value;
        }

        public string CookieDomain
        {
            get => Get<string>("SessionCookieDomain");
            set => this["SessionCookieDomain"] = value;
        }

        public CookieConsentSettings CookieConsentSettings
        {
            get => Get<CookieConsentSettings>("CookieConsentSettings");
            set => this["CookieConsentSettings"] = value;
        }

        public UsageStatisticsSettings UsageStatisticsSettings
        {
            get => Get<UsageStatisticsSettings>("UsageStatisticsSettings");
            set => this["UsageStatisticsSettings"] = value;
        }

        public Version Version
        {
            get => Get<Version>("Version");
            set => this["Version"] = value;
        }

        public string IisAppInfoProfiles
        {
            get => Get<string>("IisAppInfoProfiles");
            set => this["IisAppInfoProfiles"] = value;
        }

        public bool IsE2EMode
        {
            get => Get<bool>("IsE2EMode");
            set => this["IsE2EMode"] = value;
        }

        public bool BypassSslCertificateCheck
        {
            get => Get<bool>("BypassSslCertificateCheck");
            set => this["BypassSslCertificateCheck"] = value;
        }

        public SetupSettings SetupSettings
        {
            get => _setupSettings;
            set
            {
                _setupSettings = value;

                if (value != null)
                {
                    IisSite = value.IisSite;
                    IisPath = value.IisPath;
                    StorageLocation = value.StorageLocation;
                    DatabaseUsername = value.DatabaseUsername;
                    DatabasePassword = value.DatabasePassword;
                    NewInstancePath = value.NewInstancePath;
                    Version = value.Version;
                    AuthenticationMode = value.AuthenticationMode;
                    Authentication2FAMode = value.Authentication2FAMode;
                    IpPlatformSettings = value.IpPlatformSettings;
                    AdfsSettings = value.AdfsSettings;
                    IntegrationServerPort = value.IntegrationServerPort;
                    RemoteIntegrationServerUrl = value.RemoteIntegrationServerUrl;
                    RemoteStorageServiceUrl = value.RemoteStorageServiceUrl;
                    CookieName = value.CookieName;
                    CookiePath = value.CookiePath;
                    CookieDomain = value.CookieDomain;
                    CookieConsentSettings = value.CookieConsentSettings;
                    UsageStatisticsSettings = value.UsageStatisticsSettings;
                    IsE2EMode = value.IsE2EMode;
                    BypassSslCertificateCheck = value.BypassSslCertificateCheck;
                }
            }
        }

        public IisAppInfo PairedIisApp
        {
            get => _pairedIisApp;
            set
            {
                _pairedIisApp = value;

                if (value != null)
                {
                    this["Site"] = value.Site;
                    this["VirtualPath"] = value.VirtualPath;
                    this["PhysicalPath"] = value.PhysicalPath;
                    this["ApplicationPool"] = value.ApplicationPool;
                    this["Protocols"] = value.Protocols;
                    this["ServiceUser"] = value.ServiceUser;
                    this["IsBuiltInServiceUser"] = value.IsBuiltInServiceUser;
                    this["ProcessModelIdentityType"] = value.IdentityType.ToString();
                    this["Username"] = value.Username;
                    this["Password"] = value.Password;
                    this["BindingUrls"] = value.BindingUrls;
                    this["InprotechServerVersion"] = value.Version;
                    this["InprotechConnectionString"] = value.WebConfig.InprotechConnectionString;
                    this["IisAuthenticationMode"] = value.GetAuthenticationMode();
                    this["SessionTimeout"] = value.WebConfig.TimeoutInterval;
                    this["SessionCookieName"] = value.WebConfig.CookieName;
                    this["SessionCookiePath"] = value.WebConfig.CookiePath;
                    this["SessionCookieDomain"] = value.WebConfig.CookieDomain;
                    this["FeaturesAvailable"] = value.WebConfig.FeaturesAvailable;
                    this["SmtpServer"] = value.WebConfig.SmtpServer;
                    this["IwsMachineName"] = value.WebConfig.IwsMachineName;
                    this["IwsDmsMachineName"] = value.WebConfig.IwsDmsMachineName;
                    this["ReportProvider"] = value.WebConfig.ReportProvider;
                    this["IwsReportsMachineName"] = value.WebConfig.IwsReportsMachineName;
                    this["ReportServiceEntryFolder"] = value.WebConfig.ReportServiceEntryFolder;
                    this["ReportServiceUrl"] = value.WebConfig.ReportServiceUrl;
                    this["IwsAttachmentMachineName"] = value.WebConfig.IwsAttachmentMachineName;
                    this["InprotechVersionFriendlyName"] = value.WebConfig.InprotechVersionFriendlyName;
                }
            }
        }

        public SetupWorkflow Workflow { get; set; }
        
        public void Reset()
        {
            Clear();

            BackupDirectory = Constants.BackupDirectory;
            Workflow = null;
            SetupSettings = null;

            if (SetupEnvironment.IsUiMode)
            {
                this["Dispatcher"] = SetupEnvironment.Dispatcher;
            }
        }

        T Get<T>(string key)
        {
            if (!TryGetValue(key, out var result))
            {
                return default(T);
            }

            return (T) result;
        }
    }
}