using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class UpdateInprotechServerConfiguration : ISetupAction
    {
        public string Description => "Update Inprotech Server configuration";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var version = (Version) context["InprotechServerVersion"];
            var inprotechServerVersion = version.ToString();
            var inprotechVersionFriendlyName =Convert.ToString(context["InprotechVersionFriendlyName"]);
            var ipPlatformSettings = (context.ContainsKey("IpPlatformSettings") ? context["IpPlatformSettings"] : null) as IpPlatformSettings;

            var ipAddress = IPAddress.None;
            if (!NetworkUtility.TryGetPublicIpAddress(out ipAddress, out var error))
            {
                eventStream.PublishWarning($"Unable to resolve public IP Address. {Environment.NewLine}{error}");
            }

            var cookiePath = context.ContainsKey("SessionCookiePath") ? (string) context["SessionCookiePath"] : null;

            var addOrUpdateSettings = new Dictionary<string, string>
            {
                {
                    "InstanceName",
                    (string) context["InstanceName"]
                },
                {
                    "BindingUrls",
                    (string) context["BindingUrls"]
                },
                {
                    "ParentPath",
                    ((string) context["VirtualPath"]).AsAppSettingsCompatiblePath()
                },
                {
                    "AuthenticationMode",
                    (string) context["AuthenticationMode"]
                },
                {
                    "Authentication2FAMode",
                    (string) context["Authentication2FAMode"]
                },
                {
                    "IntegrationServerBaseUrl",
                    GetIntegrationServerBaseUrl(context)
                },
                {
                    "StorageServiceBaseUrl",
                    GetStorageServiceBaseUrl(context)
                },
                {
                    "UseDirectDataServices",
                    (!HasFeature(context["FeaturesAvailable"], IisAppFeatures.AppsBridgeHttpModule)).ToString()
                },
                {
                    "InprotechVersion",
                    inprotechServerVersion
                },
                {
                    "InprotechVersionFriendlyName",
                    inprotechVersionFriendlyName
                },
                {
                    "ContactUsEmailAddress",
                    (context as SetupContext)?.PairedIisApp?.WebConfig?.ContactUsEmailAddress
                },
                {
                    "SessionTimeout",
                    context.ContainsKey("SessionTimeout") && !string.IsNullOrWhiteSpace((string) context["SessionTimeout"]) ? (string) context["SessionTimeout"] : null
                },
                {
                    "SessionCookieName",
                    context.ContainsKey("SessionCookieName") ? (string) context["SessionCookieName"] : null
                },
                {
                    "SessionCookieDomain",
                    context.ContainsKey("SessionCookieDomain") ? (string) context["SessionCookieDomain"] : null
                },
                {
                    "SessionCookiePath",
                    string.IsNullOrWhiteSpace(cookiePath) ? "/" : cookiePath
                },
                {
                    "LegacySqlVersion",
                    !string.IsNullOrWhiteSpace((string) context["InprotechConnectionString"]) ? VersionNumberUtitlity.IsLegacyVersion((string) context["InprotechConnectionString"]).ToString() : null
                },
                {
                    "PublicIpAddress", ipAddress == IPAddress.None ? string.Empty : ipAddress.ToString()
                },
                {
                    "EnableHsts",
                    (context as SetupContext)?.PairedIisApp?.WebConfig?.EnableHsts
                },
                {
                    "HstsMaxAge",
                    (context as SetupContext)?.PairedIisApp?.WebConfig?.HstsMaxAge
                }
            };

            if (context.ContainsKey("IsE2EMode") && (bool) context["IsE2EMode"])
            {
                addOrUpdateSettings["e2e"] = "true";
            }

            if (ipPlatformSettings != null)
            {
                addOrUpdateSettings[Constants.IpPlatformSettings.ClientId] = ipPlatformSettings.ClientId;
                addOrUpdateSettings[Constants.IpPlatformSettings.ClientSecret] = ipPlatformSettings.ClientSecret;
            }

            AddDefaultInprotechWikiLink(context, addOrUpdateSettings);

            ConfigurationUtility.AddUpdateAppSettings(context.InprotechServerConfigFilePath(), addOrUpdateSettings);
        }

        string GetIntegrationServerBaseUrl(IDictionary<string, object> context)
        {
            if (context.TryGetValidRemoteIntegrationServerUrl(out var remoteIntegrationServerUri))
            {
                // Uses a different integration server
                return remoteIntegrationServerUri.ToString().TrimEnd('/') + '/';
            }

            var appSettings = ConfigurationUtility.ReadAppSettings(context.InprotechIntegrationServerConfigFilePath());

            var path = appSettings["Path"];
            var port = context["IntegrationServer.Port"];

            return $"http://localhost:{port}/{context.InstanceSpecificLiteral(path)}/";
        }

        string GetStorageServiceBaseUrl(IDictionary<string, object> context)
        {
            if (context.TryGetValidRemoteStorageServiceUrl(out var remoteStorageServiceUri))
            {
                // Uses a different integration server
                return remoteStorageServiceUri.ToString().TrimEnd('/') + '/';
            }

            var appSettings = ConfigurationUtility.ReadAppSettings(context.InprotechStorageServiceConfigFilePath());

            var path = appSettings["Path"];
            var port = context["IntegrationServer.Port"];

            return $"http://localhost:{port}/{context.InstanceSpecificLiteral(path)}/";
        }

        void AddDefaultInprotechWikiLink(IDictionary<string, object> context, IDictionary<string, string> addOrUpdateSettings)
        {
            const string key = "InprotechWikiLink";
            var appSettings = ConfigurationUtility.ReadAppSettings(context.InprotechServerConfigFilePath());
            if (!appSettings.ContainsKey(key))
            {
                addOrUpdateSettings.Add(key, "http://inprowiki.com/forum");
            }
        }

        static bool HasFeature(object features, string featureToCheck)
        {
            var all = features as IEnumerable<string>;

            return all != null && all.Contains(featureToCheck);
        }
    }
}