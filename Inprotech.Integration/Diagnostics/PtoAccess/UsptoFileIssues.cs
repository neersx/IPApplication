using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.PtoAccess;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class UsptoFileIssues : IDiagnosticsArtefacts
    {
        readonly ICompressionHelper _compressionHelper;
        readonly IFileSystem _fileSystem;
        readonly IUsptoMessageFileLocationResolver _usptoMessageFileLocationResolver;
        public UsptoFileIssues(ICompressionHelper compressionHelper, IUsptoMessageFileLocationResolver usptoMessageFileLocationResolver, IFileSystem fileSystem)
        {
            _compressionHelper = compressionHelper;
            _usptoMessageFileLocationResolver = usptoMessageFileLocationResolver;
            _fileSystem = fileSystem;
        }

        public string Name => "IPOne.zip";

        public async Task Prepare(string basePath)
        {
            PrepareUsptoFiles(basePath);
        }

        void PrepareUsptoFiles(string basePath)
        {
            var fileLocation = _usptoMessageFileLocationResolver.ResolveMessagePath();

            if (!_fileSystem.FolderExists(_fileSystem.AbsolutePath(fileLocation)) || !_fileSystem.Files(fileLocation, "*.json").Any())
            {
                return;
            }

            var baseFile = _usptoMessageFileLocationResolver.ResolveRootDirectory();
            _compressionHelper.CreateFromDirectory(_fileSystem.AbsolutePath(baseFile), Path.Combine(basePath, Name));
        }
    }
}