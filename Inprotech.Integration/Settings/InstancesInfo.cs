using System;
using System.Collections.Generic;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Hosting;

namespace Inprotech.Integration.Settings
{
    public interface IInstancesInfo
    {
        IEnumerable<InstanceServiceStatus> ServerInstances();
        IEnumerable<InstanceServiceStatus> IntegrationServerInstances();
    }

    public class InstancesInfo : IInstancesInfo
    {
        readonly Func<string, IGroupedConfig> _groupedConfig;

        public InstancesInfo(Func<string, IGroupedConfig> groupedConfig)
        {
            _groupedConfig = groupedConfig;
        }

        public IEnumerable<InstanceServiceStatus> ServerInstances()
        {
            return FromSettings(_groupedConfig("Inprotech.Server"));
        }

        public IEnumerable<InstanceServiceStatus> IntegrationServerInstances()
        {
            return FromSettings(_groupedConfig("Inprotech.IntegrationServer"));
        }

        static IEnumerable<InstanceServiceStatus> FromSettings(IGroupedConfig group)
        {
            var values = group.GetValues("Instances");
            return values["Instances"].FromConfigSettings();
        }
    }
}