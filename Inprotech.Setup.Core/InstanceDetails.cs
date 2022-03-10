using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace Inprotech.Setup.Core
{
    public enum ServiceStatus
    {
        Online,
        Offline
    }

    public class InstanceServiceStatus
    {
        public string Name { get; set; }

        public string MachineName { get; set; }
        
        public string Version { get; set; }

        [JsonConverter(typeof(StringEnumConverter))]
        public ServiceStatus Status { get; set; }

        public DateTime Utc { get; set; }

        public string InstanceDescription => $"{MachineName} ({Version})";

        public IEnumerable<string> Endpoints { get; set; }

        public InstanceServiceStatus()
        {
             Endpoints = new List<string>();
        }
    }
    
    public static class InstanceServiceStatusExtension
    {
        public static InstanceServiceStatus ByName(this IEnumerable<InstanceServiceStatus> instances, string name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            return instances.SingleOrDefault(_ => _.Name == name);
        }
    }

    public class HostApplication
    {
        public HostApplication(string name)
        {
            Name = name;
        }

        public string Name { get; }
    }

    public class InstanceDetails
    {
        public ICollection<InstanceServiceStatus> InprotechServer { get; set; }

        public ICollection<InstanceServiceStatus> IntegrationServer { get; set; }

        public InstanceDetails()
        {
            InprotechServer = new InstanceServiceStatus[0];
            IntegrationServer = new InstanceServiceStatus[0];
        }

        public InstanceDetails(string inprotechServerJson, string integrationServerJson)
        {
            InprotechServer = InstanceDetailsHelper.From(inprotechServerJson);
            IntegrationServer = InstanceDetailsHelper.From(integrationServerJson);
        }
    }

    public static class InstanceDetailsHelper
    {
        public static ICollection<InstanceServiceStatus> From(string json)
        {
            return string.IsNullOrWhiteSpace(json) 
                ? new InstanceServiceStatus[0] 
                : JsonConvert.DeserializeObject<ICollection<InstanceServiceStatus>>(json);
        }

        public static string AsJson (this ICollection<InstanceServiceStatus> instances)
        {
            return JsonConvert.SerializeObject(instances);
        }

        public static bool RemoveInstance(this InstanceDetails details, string instanceName)
        {
            var removed = false;

            var inprotechServer = details.InprotechServer.ByName(instanceName);
            if (inprotechServer != null)
            {
                details.InprotechServer.Remove(inprotechServer);
                removed = true;
            }

            var integrationServer = details.IntegrationServer.ByName(instanceName);
            if (integrationServer != null)
            {
                details.IntegrationServer.Remove(integrationServer);
                removed = true;
            }

            return removed;
        }
    }
}
