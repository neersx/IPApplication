using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class DocumentIssues : IDiagnosticsArtefacts
    {
        readonly IRepository _repository;
        readonly ISimpleExcelExporter _excelExporter;
        readonly IFileSystem _fileSystem;

        const string ArtefactName = "DocumentIssues.xlsx";

        public DocumentIssues(IRepository repository, ISimpleExcelExporter excelExporter, IFileSystem fileSystem)
        {
            _repository = repository;
            _excelExporter = excelExporter;
            _fileSystem = fileSystem;
        }

        public string Name => ArtefactName;

        public async Task Prepare(string basePath)
        {
            var errors = from dn in _repository.Set<Document>()
                         where dn.Errors != null
                         orderby dn.UpdatedOn
                         select new DocumentLevelErrorDetail
                                {
                                    Id = dn.Id,
                                    ApplicationNumber = dn.ApplicationNumber,
                                    PublicationNumber = dn.PublicationNumber,
                                    RegistrationNumber = dn.RegistrationNumber,
                                    RawError = dn.Errors,
                                    Date = dn.UpdatedOn
                                };

            if (!errors.Any())
                return;

            using (var ci = _fileSystem.OpenWrite(Path.Combine(basePath, ArtefactName)))
            {
                var ex = _excelExporter.Export(errors);
                await ex.CopyToAsync(ci);
            }
        }
    }
}