using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class CaseIssues : IDiagnosticsArtefacts
    {
        readonly IRepository _repository;
        readonly ISimpleExcelExporter _excelExporter;
        readonly IFileSystem _fileSystem;

        const string ArtefactName = "CaseIssues.xlsx";

        public CaseIssues(IRepository repository, ISimpleExcelExporter excelExporter, IFileSystem fileSystem)
        {
            _repository = repository;
            _excelExporter = excelExporter;
            _fileSystem = fileSystem;
        }

        public string Name => ArtefactName;

        public async Task Prepare(string basePath)
        {
            var errors = from cn in _repository.Set<CaseNotification>()
                         where cn.Type == CaseNotificateType.Error
                         join c in _repository.Set<Case>() on cn.CaseId equals c.Id into cnl
                         from c in cnl.DefaultIfEmpty()
                         orderby c.Source, cn.UpdatedOn descending 
                         select new CaseLevelErrorDetail
                                {
                                    Id = cn.CaseId,
                                    ApplicationNumber = c.ApplicationNumber,
                                    PublicationNumber = c.PublicationNumber,
                                    RegistrationNumber = c.RegistrationNumber,
                                    RawError = cn.Body,
                                    Date = cn.UpdatedOn,
                                    IdentifiedInprotechCaseId = c.CorrelationId
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