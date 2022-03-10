using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace Inprotech.Infrastructure.Hosting
{
    /// <summary>
    /// Should not rename this class and its properties
    /// This is shared by the setup project and must remain backward compatible
    /// </summary>
    public class InstanceServiceStatus
    {
        public string Name { get; set; }

        public string MachineName { get; set; }
        
        public string Version { get; set; }

        [JsonConverter(typeof(StringEnumConverter))]
        public ServiceStatus Status { get; set; }

        public DateTime Utc { get; set; }

        public IEnumerable<string> Endpoints { get; set; }

        public InstanceServiceStatus()
        {
            Endpoints = new List<string>();
        }
    }
}