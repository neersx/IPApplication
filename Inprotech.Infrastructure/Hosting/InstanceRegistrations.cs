using System;
using System.Collections.Generic;
using Inprotech.Contracts;
using Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion.Extensions;
using Newtonsoft.Json;

namespace Inprotech.Infrastructure.Hosting
{
    public interface IInstanceRegistrations
    {
        void RegisterSelf(ServiceStatus status, IEnumerable<string> endpoints);
    }

    public class InstanceRegistrations : IInstanceRegistrations
    {
        readonly string _hostApplicationName;
        readonly string _instanceName;
        readonly Func<string, IGroupedConfig> _groupedConfig;
        readonly Func<DateTime> _systemClock;

        public InstanceRegistrations(
            Func<HostApplication> hostApplication, 
            Func<string, IGroupedConfig> groupedConfig, 
            Func<DateTime> systemClock, 
            IAppSettingsProvider appSettingsProvider)
        {
            _groupedConfig = groupedConfig;
            _systemClock = systemClock;
            _hostApplicationName = hostApplication().Name;
            _instanceName = appSettingsProvider["InstanceName"];
        }

        public void RegisterSelf(ServiceStatus status, IEnumerable<string> endpoints)
        {
            var config = _groupedConfig(_hostApplicationName);

            var instances = Resolve(config["Instances"]);

            var instance = instances.ByName(_instanceName);

            instance.Status = status;
            instance.Version = GetType().Assembly.Version();
            instance.Utc = _systemClock().ToUniversalTime();
            
            instance.Endpoints = new List<string>(endpoints);

            config.SetValue("Instances", JsonConvert.SerializeObject(instances, Newtonsoft.Json.Formatting.None));
        }

        List<InstanceServiceStatus> Resolve(string existing)
        {
            var instances = new List<InstanceServiceStatus>();

            if (!string.IsNullOrWhiteSpace(existing))
            {
                var existingObjects = JsonConvert.DeserializeObject<IEnumerable<InstanceServiceStatus>>(existing);
                instances.AddRange(existingObjects);
            }

            if (instances.ByName(_instanceName) == null)
            {
                instances.Add(new InstanceServiceStatus
                {
                    Name = _instanceName,
                    MachineName = Environment.MachineName
                });
            }

            return instances;
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
}