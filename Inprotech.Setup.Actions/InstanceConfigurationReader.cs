using System;
using System.Collections.Generic;
using System.IO;
using System.ServiceProcess;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class InstanceConfigurationReader : IInstanceConfigurationReader
    {
        public IEnumerable<InstanceComponentConfiguration> Read(string instancePath)
        {
            var instanceName = Path.GetFileName(instancePath);

            var inprotechServerConfig = new InstanceComponentConfiguration
            {
                Name = "Inprotech Server",
                Configuration = ReadInprotechServerConfiguration(instancePath, instanceName),
                AppSettings = ReadInprotechServerAppSettings(instancePath)
            };

            var integrationServerConfig = new InstanceComponentConfiguration
            {
                Name = "Inprotech Integration Server",
                Configuration = ReadInprotechIntegrationConfiguration(instancePath, instanceName, inprotechServerConfig.AppSettings),
                AppSettings = ReadInprotechIntegrationAppSettings(instancePath)
            };

            var storageServiceConfig = new InstanceComponentConfiguration
            {
                Name = "Inprotech Storage Service",
                Configuration = ReadInprotechStorageServiceConfiguration(instancePath, instanceName, inprotechServerConfig.AppSettings),
                AppSettings = ReadInprotechStorageServiceAppSettings(instancePath)
            };

            yield return inprotechServerConfig;

            yield return integrationServerConfig;

            yield return storageServiceConfig;
        }

        static IDictionary<string, string> ReadInprotechServerAppSettings(string instancePath)
        {
            return ConfigurationUtility.ReadAppSettings(Path.Combine(instancePath, "inprotech.server", "inprotech.server.exe.config"));
        }

        static IDictionary<string, string> ReadInprotechServerConfiguration(string instancePath, string instanceName)
        {
            var result = new Dictionary<string, string>();

            var configPath = Path.Combine(instancePath, "inprotech.server", "inprotech.server.exe.config");

            var connectionString = ConfigurationUtility.ReadConnectionString(configPath, "Inprotech");

            result.Add("Status", GetServiceStatus("Inprotech.Server", instanceName));

            result.Add("ConnectionString", connectionString);

            result.Add("ServiceAccount", GetServiceAccount("Inprotech.Server", instanceName));

            return result;
        }

        static IDictionary<string, string> ReadInprotechIntegrationAppSettings(string instancePath)
        {
            return ConfigurationUtility.ReadAppSettings(Path.Combine(instancePath, "inprotech.integrationserver", "inprotech.integrationServer.exe.config"));
        }

        static IDictionary<string, string> ReadInprotechIntegrationConfiguration(string instancePath, string instanceName, IDictionary<string, string> inprotechServerAppSettings)
        {
            var result = new Dictionary<string, string>();

            if (Uri.TryCreate(inprotechServerAppSettings["IntegrationServerBaseUrl"], UriKind.Absolute, out Uri uri))
            {
                if (uri.Host != "localhost")
                {
                    result.Add("Status", "Not Installed");

                    result.Add("Remote Instance", uri.ToString());

                    result.Add("Hide AppSettings", string.Empty);

                    return result;
                }
            }

            var configPath = Path.Combine(instancePath, "inprotech.integrationserver", "inprotech.integrationserver.exe.config");

            var connectionString = ConfigurationUtility.ReadConnectionString(configPath, "InprotechIntegration");

            result.Add("Status", GetServiceStatus("Inprotech.IntegrationServer", instanceName));

            result.Add("ConnectionString", connectionString);

            result.Add("ServiceAccount", GetServiceAccount("Inprotech.IntegrationServer", instanceName));

            return result;
        }

        static IDictionary<string, string> ReadInprotechStorageServiceAppSettings(string instancePath)
        {
            return ConfigurationUtility.ReadAppSettings(Path.Combine(instancePath, Constants.StorageService.Folder, Constants.StorageService.Config));
        }

        static IDictionary<string, string> ReadInprotechStorageServiceConfiguration(string instancePath, string instanceName, IDictionary<string, string> inprotechServerAppSettings)
        {
            var result = new Dictionary<string, string>();

            if (Uri.TryCreate(inprotechServerAppSettings["StorageServiceBaseUrl"], UriKind.Absolute, out Uri uri))
            {
                if (uri.Host != "localhost")
                {
                    result.Add("Status", "Not Installed");

                    result.Add("Remote Instance", uri.ToString());

                    result.Add("Hide AppSettings", string.Empty);

                    return result;
                }
            }

            var configPath = Path.Combine(instancePath, "inprotech.storageservice", "inprotech.storageservice.exe.config");

            var connectionString = ConfigurationUtility.ReadConnectionString(configPath, "InprotechIntegration");

            result.Add("Status", GetServiceStatus("Inprotech.IntegrationServer", instanceName));

            result.Add("ConnectionString", connectionString);

            result.Add("ServiceAccount", GetServiceAccount("Inprotech.StorageService", instanceName));

            return result;
        }

        static string GetServiceStatus(string serviceName, string instanceName)
        {
            var sc = new ServiceController($"{serviceName}${instanceName}");
            try
            {
                return sc.Status.ToString();
            }
            catch
            {
                return "Not Available";
            }
        }

        static string GetServiceAccount(string serviceName, string instanceName)
        {
            var serviceAccount = "Not Available";
            try
            {
                var fullServiceName = $"{serviceName}${instanceName}";
                var query = new System.Management.SelectQuery($"select name, startname from Win32_Service where name = '{fullServiceName}'");
                using (var searcher = new System.Management.ManagementObjectSearcher(query))
                {
                    foreach (var service in searcher.Get())
                    {
                        serviceAccount = service["startname"] as string;
                        break;
                    }
                }
            }
            catch
            {
                return "Not Available";
            }

            return serviceAccount;
        }
    }
}