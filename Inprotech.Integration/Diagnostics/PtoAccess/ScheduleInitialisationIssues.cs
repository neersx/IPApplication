using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class ScheduleInitialisationIssues : IDiagnosticsArtefacts
    {
        readonly IRepository _repository;
        readonly IFileSystem _fileSystem;
        readonly ICompressionHelper _compressionHelper;
        readonly ISimpleExcelExporter _excelExporter;

        const string Addendum = "addendum.zip";
        const string ArtefactName = "ScheduleInitialisationIssues.xlsx";

        public ScheduleInitialisationIssues(IRepository repository, IFileSystem fileSystem, ICompressionHelper compressionHelper, ISimpleExcelExporter excelExporter)
        {
            _repository = repository;
            _fileSystem = fileSystem;
            _compressionHelper = compressionHelper;
            _excelExporter = excelExporter;
        }

        public string Name => ArtefactName;

        public async Task Prepare(string basePath)
        {
            var errors = _repository.Set<ScheduleFailure>()
                                    .Where(_ => !_.Schedule.IsDeleted)
                                    .Select(_ => new ScheduleInitialisationErrorDetails
                                                 {
                                                     ScheduleId = _.Schedule.Id,
                                                     ScheduleName = _.Schedule.Name,
                                                     ScheduleType = _.Schedule.Type,
                                                     ScheduleExecutionId = _.ScheduleExecution != null ? _.ScheduleExecution.SessionGuid : Guid.Empty,
                                                     CorrelationId = _.ScheduleExecution != null ? _.ScheduleExecution.CorrelationId : null,
                                                     Date = _.Date,
                                                     RawError = _.Log
                                                 })
                                    .OrderByDescending(_ => _.Date)
                                    .ToArray();

            if (!errors.Any())
                return;

            using (var si = _fileSystem.OpenWrite(Path.Combine(basePath, ArtefactName)))
            {
                var ex = _excelExporter.Export(errors);
                await ex.CopyToAsync(si);
            }

            var additionalInfos = errors.Where(_ => !string.IsNullOrWhiteSpace(_.AdditionalInfoPath))
                                        .Select(_ => _.AdditionalInfoPath).ToArray();

            foreach (var file in additionalInfos)
            {
                if (!_fileSystem.Exists(file))
                    continue;

                await _compressionHelper.AddToArchive(Addendum, _fileSystem.AbsolutePath(file));
            }
        }
    }
}