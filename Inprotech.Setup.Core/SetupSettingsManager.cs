using System;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;

namespace Inprotech.Setup.Core
{
    public interface ISetupSettingsManager
    {
        SetupSettings Read(string instancePath);
        void Write(string instancePath, SetupSettings settings);
    }

    internal class SetupSettingsManager : ISetupSettingsManager
    {
        readonly ICryptoService _cryptoService;
        readonly IFileSystem _fileSystem;
        readonly string _privateKey;

        public SetupSettingsManager()
        {
        }

        public SetupSettingsManager(string privateKey, IFileSystem fileSystem, ICryptoService cryptoService)
        {
            _privateKey = privateKey;
            _fileSystem = fileSystem;
            _cryptoService = cryptoService;
        }

        public SetupSettings Read(string instancePath)
        {
            var filePath = Path.Combine(instancePath, Constants.SettingsFileName);

            if (!_fileSystem.FileExists(filePath))
            {
                return null;
            }

            var json = Decode(_fileSystem.ReadAllText(filePath));

            if (string.IsNullOrEmpty(json))
            {
                return null;
            }

            try
            {
                var map = JsonConvert.DeserializeObject<IDictionary<string, string>>(json);
                var settings = new SetupSettings();

                if (HasValue(map, "Status"))
                {
                    if (Enum.TryParse(map["Status"], true, out SetupStatus status))
                    {
                        settings.Status = status;
                    }
                }

                if (HasValue(map, "Action")) // legacy name for RunMode
                {
                    if (Enum.TryParse(map["Action"], true, out SetupRunMode mode))
                    {
                        settings.RunMode = mode;
                    }
                }

                if (HasValue(map, "Version"))
                {
                    if (Version.TryParse(map["Version"], out Version version))
                    {
                        settings.Version = version;
                    }
                }

                if (HasValue(map, "IisSite"))
                {
                    settings.IisSite = map["IisSite"];
                }

                if (HasValue(map, "IisPath"))
                {
                    settings.IisPath = map["IisPath"];
                }

                if (HasValue(map, "StorageLocation"))
                {
                    settings.StorageLocation = map["StorageLocation"];
                }

                if (HasValue(map, "AuthenticationMode"))
                {
                    settings.AuthenticationMode = map["AuthenticationMode"];
                }

                if (HasValue(map, "Authentication2FAMode"))
                {
                    settings.Authentication2FAMode = map["Authentication2FAMode"];
                }

                if (HasValue(map, "NewInstancePath"))
                {
                    settings.NewInstancePath = map["NewInstancePath"];
                }

                if (HasValue(map, "Database.Username"))
                {
                    settings.DatabaseUsername = map["Database.Username"];
                }

                if (HasValue(map, "Database.Password"))
                {
                    settings.DatabasePassword = map["Database.Password"];
                }

                if (HasValue(map, "IpPlatformSettings"))
                {
                    settings.IpPlatformSettings = JsonConvert.DeserializeObject<IpPlatformSettings>(map["IpPlatformSettings"]);
                }

                if (HasValue(map, "AdfsSettings"))
                {
                    settings.AdfsSettings = JsonConvert.DeserializeObject<AdfsSettings>(map["AdfsSettings"]);
                }

                if (HasValue(map, "IntegrationServer.Port"))
                {
                    settings.IntegrationServerPort = map["IntegrationServer.Port"];
                }

                if (HasValue(map, "RemoteIntegrationServerUrl"))
                {
                    settings.RemoteIntegrationServerUrl = map["RemoteIntegrationServerUrl"];
                }
                
                if (HasValue(map, "RemoteStorageServiceUrl"))
                {
                    settings.RemoteStorageServiceUrl = map["RemoteStorageServiceUrl"];
                }

                if (HasValue(map, "SessionCookieName"))
                {
                    settings.CookieName = map["SessionCookieName"];
                }

                if (HasValue(map, "SessionCookiePath"))
                {
                    settings.CookiePath = map["SessionCookiePath"];
                }

                if (HasValue(map, "SessionCookieDomain"))
                {
                    settings.CookieDomain = map["SessionCookieDomain"];
                }
                
                if (HasValue(map, "CookieConsentSettings"))
                {
                    settings.CookieConsentSettings = JsonConvert.DeserializeObject<CookieConsentSettings>(map["CookieConsentSettings"]);
                }

                if (HasValue(map, "UsageStatisticsSettings"))
                {
                    settings.UsageStatisticsSettings = JsonConvert.DeserializeObject<UsageStatisticsSettings>(map["UsageStatisticsSettings"]);
                }

                if (HasValue(map, "IisAppInfoProfiles"))
                {
                    settings.IisAppInfoProfiles = map["IisAppInfoProfiles"];
                }

                if (HasValue(map, "IsE2EMode"))
                {
                    if (bool.TryParse(map["IsE2EMode"], out bool isE2EMode))
                    {
                        settings.IsE2EMode = isE2EMode;
                    }
                }

                if (HasValue(map, "BypassSslCertificateCheck"))
                {
                    if (bool.TryParse(map["BypassSslCertificateCheck"], out bool bypassSslCertificateCheck))
                    {
                        settings.BypassSslCertificateCheck = bypassSslCertificateCheck;
                    }
                }

                return settings;
            }
            catch
            {
                return null;
            }
        }

        public void Write(string instancePath, SetupSettings settings)
        {
            var map = new Dictionary<string, string>
            {
                ["Action"] = settings.RunMode.ToString(),
                ["IisSite"] = settings.IisSite,
                ["IisPath"] = settings.IisPath,
                ["StorageLocation"] = settings.StorageLocation,
                ["IntegrationServer.Port"] = settings.IntegrationServerPort,
                ["RemoteIntegrationServerUrl"] = settings.RemoteIntegrationServerUrl,
                ["RemoteStorageServiceUrl"] = settings.RemoteStorageServiceUrl,
                ["IisAppInfoProfiles"] = settings.IisAppInfoProfiles
            };

            if (settings.AuthenticationMode != null)
            {
                map["AuthenticationMode"] = settings.AuthenticationMode;
            }

            if (settings.Authentication2FAMode != null)
            {
                map["Authentication2FAMode"] = settings.Authentication2FAMode;
            }

            if (settings.Status != null)
            {
                map["Status"] = settings.Status.ToString();
            }

            if (settings.Version != null)
            {
                map["Version"] = settings.Version.ToString();
            }

            if (settings.NewInstancePath != null)
            {
                map["NewInstancePath"] = settings.NewInstancePath;
            }

            if (settings.DatabaseUsername != null)
            {
                map["Database.Username"] = settings.DatabaseUsername;
            }

            if (settings.DatabasePassword != null)
            {
                map["Database.Password"] = settings.DatabasePassword;
            }

            if (settings.IpPlatformSettings != null)
            {
                map["IpPlatformSettings"] = JsonConvert.SerializeObject(settings.IpPlatformSettings);
            }

            if (settings.AdfsSettings != null)
            {
                map["AdfsSettings"] = JsonConvert.SerializeObject(settings.AdfsSettings);
            }

            if (settings.CookieName != null)
            {
                map["SessionCookieName"] = settings.CookieName;
            }

            if (settings.CookiePath != null)
            {
                map["SessionCookiePath"] = settings.CookiePath;
            }

            if (settings.CookieDomain != null)
            {
                map["SessionCookieDomain"] = settings.CookieDomain;
            }

            if (settings.CookieConsentSettings != null)
            {
                map["CookieConsentSettings"] = JsonConvert.SerializeObject(settings.CookieConsentSettings);
            }

            if (settings.IsE2EMode)
            {
                map["IsE2EMode"] = "True";
            }

            if (settings.BypassSslCertificateCheck)
            {
                map["BypassSslCertificateCheck"] = "True";
            }

            var encodedJson = Encode(JsonConvert.SerializeObject(map, Formatting.Indented));

            _fileSystem.WriteAllText(Path.Combine(instancePath, Constants.SettingsFileName), encodedJson);
        }

        string Encode(string plainText)
        {
            return _cryptoService.Encrypt(_privateKey, plainText);
        }

        string Decode(string encodedText)
        {
            return _cryptoService.TryDecrypt(_privateKey, encodedText);
        }

        static bool HasValue(IDictionary<string, string> map, string key)
        {
            return map.ContainsKey(key) && map[key] != null;
        }
    }
}