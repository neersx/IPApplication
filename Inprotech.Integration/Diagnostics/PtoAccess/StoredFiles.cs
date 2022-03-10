using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class StoredFiles : IDiagnosticsArtefacts
    {
        readonly ISimpleExcelExporter _excelExporter;
        readonly IFileSystem _fileSystem;
        readonly IFileHelpers _fileHelpers;

        const string ArtefactName = "PtoStorageFolder.xlsx";

        public StoredFiles(ISimpleExcelExporter excelExporter, IFileSystem fileSystem, IFileHelpers fileHelpers)
        {
            _excelExporter = excelExporter;
            _fileSystem = fileSystem;
            _fileHelpers = fileHelpers;
        }

        public string Name => ArtefactName;

        public async Task Prepare(string basePath)
        {
            using (var psf = _fileSystem.OpenWrite(Path.Combine(basePath, ArtefactName)))
            {
                var ex = _excelExporter.Export(GetAllPtoStorageFilesListing());
                await ex.CopyToAsync(psf);
            }
        }

        IEnumerable<StorageFileListing> GetAllPtoStorageFilesListing()
        {
            foreach (var path in FilesFromDataSourceFolder("UsptoIntegration"))
                yield return new StorageFileListing
                             {
                                 FilePath = path
                             };

            foreach (var path in FilesFromDataSourceFolder("PtoIntegration"))
                yield return new StorageFileListing
                             {
                                 FilePath = path
                             };
        }

        IEnumerable<string> FilesFromDataSourceFolder(string sourceRoot)
        {
            var filePath = _fileSystem.AbsolutePath(sourceRoot);
            if (!_fileHelpers.DirectoryExists(filePath))
                return Enumerable.Empty<string>();

            return _fileSystem.Files(sourceRoot, "*", true);
        }

        public class StorageFileListing
        {
            [ExcelHeader("File Path")]
            public string FilePath { get; set; }
        }
    }
}