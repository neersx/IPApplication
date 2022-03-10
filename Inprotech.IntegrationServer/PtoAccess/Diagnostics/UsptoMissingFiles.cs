using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration.Diagnostics.PtoAccess;

namespace Inprotech.IntegrationServer.PtoAccess.Diagnostics
{
    class UsptoMissingFiles : IDiagnosticsArtefacts
    {
        readonly ICompressionHelper _compressionHelper;
        readonly IFileSystem _fileSystem;

        public UsptoMissingFiles(ICompressionHelper compressionHelper, IFileSystem fileSystem)
        {
            _compressionHelper = compressionHelper;
            _fileSystem = fileSystem;
        }

        public string Name { get; } = "UsptoIntegration-MissingDocs";

        public async Task Prepare(string basePath)
        {
            _fileSystem.EnsureFolderExists(Name);

            if (!_fileSystem.Files(Name, "*").Any()) return;

            _compressionHelper.CreateFromDirectory(_fileSystem.AbsolutePath(Name), Path.Combine(basePath, $"{Name}.zip"));
        }
    }
}