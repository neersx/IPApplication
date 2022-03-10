using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

#pragma warning disable 1998

namespace Inprotech.IntegrationServer.PtoAccess.Diagnostics
{
    public interface IRuntimeEvents
    {
        Task CaseProcessed(DataDownload dataDownload);
        Task EndSession(DataDownload dataDownload);
    }

    public class RuntimeEvents : IRuntimeEvents
    {
        readonly IArtifactsService _artefactsService;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IRepository _repository;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;

        public RuntimeEvents(IScheduleRuntimeEvents scheduleRuntimeEvents, IRepository repository,
                             IDataDownloadLocationResolver dataDownloadLocationResolver,
                             IArtifactsService artefactsService)
        {
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _repository = repository;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _artefactsService = artefactsService;
        }

        public async Task CaseProcessed(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var @case =
                _repository.Set<Case>()
                           .Single(
                                   c =>
                                       c.Source == dataDownload.DataSourceType &&
                                       c.CorrelationId == dataDownload.Case.CaseKey);

            var caseArtifactsLocation = _dataDownloadLocationResolver.Resolve(dataDownload);

            var caseArtifacts = _artefactsService.CreateCompressedArchive(caseArtifactsLocation, ErrorAction.NullIfSourcePathNotExists);

            _scheduleRuntimeEvents.CaseProcessed(dataDownload.Id, @case, caseArtifacts);
        }

        public async Task EndSession(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            _scheduleRuntimeEvents.End(dataDownload.Id);
        }
    }
}