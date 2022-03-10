using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

namespace Inprotech.Infrastructure.Hosting
{
    public static class InstanceServiceStatusExtension
    {
        public static InstanceServiceStatus ByName(this IEnumerable<InstanceServiceStatus> instances, string name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            return instances.SingleOrDefault(_ => _.Name == name);
        }

        public static IEnumerable<InstanceServiceStatus> FromConfigSettings(this string instances)
        {
            if (string.IsNullOrEmpty(instances))
                return new InstanceServiceStatus[0];

            return JsonConvert.DeserializeObject<IEnumerable<InstanceServiceStatus>>(instances);
        }
    }

}