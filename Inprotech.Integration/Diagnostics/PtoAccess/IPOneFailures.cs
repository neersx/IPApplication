using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class IpOneFailures : IDiagnosticsArtefacts
    {
        readonly IFileSystem _fileSystem;
        readonly IRepository _repository;

        public IpOneFailures(IFileSystem fileSystem, IRepository repository)
        {
            _fileSystem = fileSystem;
            _repository = repository;
        }

        public string Name => "IPOneUnprocessedMessages.json";

        public async Task Prepare(string basePath)
        {
            var failedExecutions = _repository.Set<JobExecution>()
                                              .Where(_ => _.Job.Type == "DequeueUsptoMessagesJob" && _.State != null)
                                              .Select(_ => new IpOneFailureModel
                                              {
                                                  State = _.State
                                              }).ToList();

            var messages = failedExecutions.SelectMany(_ => _.Messages());

            if (messages.Any())
            {
                _fileSystem.WriteAllText(Path.Combine(basePath, Name), JsonConvert.SerializeObject(messages));
            }
        }

        public class IpOneFailureModel
        {
            [JsonIgnore]
            public string State { get; set; }
        }
    }
}