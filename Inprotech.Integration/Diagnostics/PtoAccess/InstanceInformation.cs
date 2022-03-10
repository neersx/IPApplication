using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Integration.Settings;
using Newtonsoft.Json;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class InstanceInformation : ICompressedServerLogs
    {
        readonly IInstancesInfo _instancesInfo;
        readonly IFileSystem _fileSystem;

        public InstanceInformation(IInstancesInfo instancesInfo, IFileSystem fileSystem)
        {
            _instancesInfo = instancesInfo;
            _fileSystem = fileSystem;
        }

        public string Name => "Instances.json";

        public Task Prepare(string basePath)
        {
            var a = _instancesInfo.ServerInstances().ToArray();
            var b = _instancesInfo.IntegrationServerInstances().ToArray();
            var c = new
            {
                InprotechServer = a,
                IntegrationServer = b
            };

            _fileSystem.WriteAllText(
                                     Path.Combine(basePath, "Instances.json"),
                                     JsonConvert.SerializeObject(c, Formatting.Indented));

            return Task.FromResult(0);
        }
    }
}