using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Inprotech.Setup.Actions
{
    public static class ContextExtensions
    {
        public static string InprotechServerPhysicalPath(this IDictionary<string, object> context)
        {
            return Path.Combine((string) context["InstanceDirectory"], "Inprotech.Server");
        }

        public static string InprotechIntegrationServerPhysicalPath(this IDictionary<string, object> context)
        {
            return Path.Combine((string) context["InstanceDirectory"], "Inprotech.IntegrationServer");
        }

        public static string InprotechStorageServicePhysicalPath(this IDictionary<string, object> context)
        {
            return Path.Combine((string) context["InstanceDirectory"], "Inprotech.StorageService");
        }

        public static string InstanceSpecificLiteral(this IDictionary<string, object> context, string prefix)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (string.IsNullOrWhiteSpace(prefix)) throw new ArgumentException("A valid prefix is required.", nameof(prefix));

            var uriSafeInstanceName = ((string) context["InstanceName"]).Replace($"-{Environment.MachineName}".ToLower(), string.Empty);

            return $"{prefix}-{uriSafeInstanceName}";
        }

        public static IEnumerable<string> BindingUrls(this IDictionary<string, object> context, string path)
        {
            return from url in ((string) context["BindingUrls"]).Split(',')
                   select $"{url}{(path.StartsWith("/") ? string.Empty : "/")}{path}";
        }

        public static string InprotechServerConfigFilePath(this IDictionary<string, object> context)
        {
            return Path.Combine(InprotechServerPhysicalPath(context), "Inprotech.Server.exe.config");
        }

        public static string InprotechIntegrationServerConfigFilePath(this IDictionary<string, object> context)
        {
            return Path.Combine(InprotechIntegrationServerPhysicalPath(context), "Inprotech.IntegrationServer.exe.config");
        }

        public static string InprotechStorageServiceConfigFilePath(this IDictionary<string, object> context)
        {
            return Path.Combine(InprotechStorageServicePhysicalPath(context), "Inprotech.StorageService.exe.config");
        }

        public static bool TryGetValidRemoteIntegrationServerUrl(this IDictionary<string, object> context, out Uri remoteIntegrationServerUri)
        {
            var remoteIntegrationServerUrl = (string) context["RemoteIntegrationServerUrl"];
            if (!string.IsNullOrWhiteSpace(remoteIntegrationServerUrl) &&
                Uri.TryCreate(remoteIntegrationServerUrl, UriKind.Absolute, out Uri uri))
            {
                remoteIntegrationServerUri = uri;
                return true;
            }

            remoteIntegrationServerUri = null;
            return false;
        }

        public static bool TryGetValidRemoteStorageServiceUrl(this IDictionary<string, object> context, out Uri remoteIntegrationServerUri)
        {
            var remoteStorageServiceUrl = (string) context["RemoteStorageServiceUrl"];
            if (!string.IsNullOrWhiteSpace(remoteStorageServiceUrl) &&
                Uri.TryCreate(remoteStorageServiceUrl, UriKind.Absolute, out Uri uri))
            {
                remoteIntegrationServerUri = uri;
                return true;
            }

            remoteIntegrationServerUri = null;
            return false;
        }

        public static bool UseRemoteIntegrationServer(this IDictionary<string, object> context)
        {
            return context.TryGetValidRemoteIntegrationServerUrl(out Uri _);
        }

        public static bool UseRemoteStorageService(this IDictionary<string, object> context)
        {
            return context.TryGetValidRemoteStorageServiceUrl(out Uri _);
        }
    }
}