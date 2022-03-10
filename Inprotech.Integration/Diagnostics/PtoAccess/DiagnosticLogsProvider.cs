using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public interface IDiagnosticLogsProvider
    {
        bool DataAvailable { get; }
        Task<Stream> Export();
    }

    public class DiagnosticLogsProvider : IDiagnosticLogsProvider
    {
        readonly IRepository _repository;
        readonly ICompressedServerLogs _compressedServerLogs;
        readonly IIntegrationServerClient _integrationServerClient;
        readonly IFileSystem _fileSystem;
        readonly ICompressionUtility _compressionUtility;

        public DiagnosticLogsProvider(IRepository repository, ICompressedServerLogs compressedServerLogs, IIntegrationServerClient integrationServerClient, IFileSystem fileSystem, ICompressionUtility compressionUtility)
        {
            _repository = repository;
            _compressedServerLogs = compressedServerLogs;
            _integrationServerClient = integrationServerClient;
            _fileSystem = fileSystem;
            _compressionUtility = compressionUtility;
        }

        public bool DataAvailable => _repository.Set<Schedule>().WithoutDeleted().Any();

        public async Task<Stream> Export()
        {
            var path = _fileSystem.AbsoluteUniquePath("temp", Path.GetRandomFileName());

            using (var archive = _fileSystem.OpenWrite(path))
            using (var r = await _integrationServerClient.GetResponse("api/ptoaccess/diagnostic-logs/export"))
            {
                r.EnsureSuccessStatusCode();
                using (var s = await r.Content.ReadAsStreamAsync())
                    await s.CopyToAsync(archive);
            }

            await _compressionUtility.AppendArchive(path, new[] {_compressedServerLogs});

            return _fileSystem.OpenRead(path);
        }
    }
}