using System.Collections.Generic;

namespace Inprotech.Setup.Contracts.Immutable
{
    public interface IInstanceConfigurationReader
    {
        IEnumerable<InstanceComponentConfiguration> Read(string instancePath);
    }

    public class InstanceComponentConfiguration
    {
        public string Name { get; set; }
        public IDictionary<string, string> Configuration { get; set; }
        public IDictionary<string, string> AppSettings { get; set; }
    }
}