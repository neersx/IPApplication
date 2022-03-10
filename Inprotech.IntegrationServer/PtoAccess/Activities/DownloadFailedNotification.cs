using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Activities
{
    public interface IDownloadFailedNotification
    {
        Task Notify(DataDownload dataDownload);
    }

    public class DownloadFailedNotification : IDownloadFailedNotification
    {
        readonly IRepository _repository;
        readonly Func<DateTime> _now;
        readonly IGlobErrors _globErrors;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IArtifactsService _artefactsService;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;

        public DownloadFailedNotification(IRepository repository, Func<DateTime> now,
            IGlobErrors globErrors,
            IDataDownloadLocationResolver dataDownloadLocationResolver,
            IArtifactsService artefactsService,
            IScheduleRuntimeEvents scheduleRuntimeEvents)
        {
            _repository = repository;
            _now = now;
            _globErrors = globErrors;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _artefactsService = artefactsService;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
        }

        public async Task Notify(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var @case =
                _repository.Set<Case>()
                    .SingleOrDefault(
                        n => n.Source == dataDownload.DataSourceType && n.CorrelationId == dataDownload.Case.CaseKey);

            var caseExists = @case != null;

            DateTime? existingNotificationDate = null;
            if (!caseExists)
            {
                @case = _repository.Set<Case>().Add(
                    new Case
                    {
                        CorrelationId = dataDownload.Case.CaseKey,
                        ApplicationNumber = dataDownload.Case.ApplicationNumber,
                        RegistrationNumber = dataDownload.Case.RegistrationNumber,
                        PublicationNumber = dataDownload.Case.PublicationNumber,
                        Source = dataDownload.DataSourceType,
                        CreatedOn = _now(),
                        UpdatedOn = _now()
                    });
            }
            else
            {
                var existingNotification =
                    _repository.Set<CaseNotification>().SingleOrDefault(cn => cn.CaseId == @case.Id);

                if (existingNotification != null)
                {
                    existingNotificationDate = existingNotification.CreatedOn;
                    _repository.Set<CaseNotification>().Remove(existingNotification);
                }
            }

            _repository.Set<CaseNotification>().Add(new CaseNotification
            {
                Type = CaseNotificateType.Error,
                Case = @case,
                Body = JsonConvert.SerializeObject(await _globErrors.For(dataDownload)),
                CreatedOn = existingNotificationDate ?? _now(),
                UpdatedOn = _now(),
                IsReviewed = false,
                ReviewedBy = null
            });

            _repository.SaveChanges();

            var location = _dataDownloadLocationResolver.ResolveForErrorLog(dataDownload);
            var artifacts = _artefactsService.CreateCompressedArchive(location);

            _scheduleRuntimeEvents.CaseFailed(dataDownload.Id, @case, artifacts);
        }
    }
}
