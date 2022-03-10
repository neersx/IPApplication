using System;
using System.Data.Entity;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IApplicationDownloadFailed
    {
        Task SaveArtifactAndNotify(ApplicationDownload application);
    }

    public class ApplicationDownloadFailed : IApplicationDownloadFailed
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IArtifactsService _artifactsService;
        readonly IGlobErrors _exceptionGlobber;
        readonly Func<DateTime> _now;
        readonly IRepository _repository;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;

        public ApplicationDownloadFailed(IRepository repository, Func<DateTime> now,
                                         IGlobErrors exceptionGlobber,
                                         IArtifactsLocationResolver artifactsLocationResolver,
                                         IArtifactsService artifactsService,
                                         IScheduleRuntimeEvents scheduleRuntimeEvents)
        {
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _repository = repository;
            _now = now;
            _exceptionGlobber = exceptionGlobber;
            _artifactsService = artifactsService;
            _artifactsLocationResolver = artifactsLocationResolver;
        }

        public async Task SaveArtifactAndNotify(ApplicationDownload application)
        {
            var @case =
                await _repository.Set<Case>()
                                 .SingleOrDefaultAsync(
                                                       n => n.Source == DataSourceType.UsptoPrivatePair && n.ApplicationNumber == application.Number);

            var caseExists = @case != null;

            if (!caseExists)
            {
                @case = _repository.Set<Case>().Add(
                                                    new Case
                                                    {
                                                        ApplicationNumber = application.Number,
                                                        Source = DataSourceType.UsptoPrivatePair,
                                                        CreatedOn = _now(),
                                                        UpdatedOn = _now()
                                                    });
            }

            DateTime? existingNotificationDate = null;
            if (caseExists)
            {
                var existingNotification =
                    await _repository.Set<CaseNotification>().SingleOrDefaultAsync(cn => cn.CaseId == @case.Id);

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
                Body = JsonConvert.SerializeObject(await _exceptionGlobber.GlobFor(application)),
                CreatedOn = existingNotificationDate ?? _now(),
                UpdatedOn = _now(),
                IsReviewed = false,
                ReviewedBy = null
            });

            var caseArtifactsLocation = _artifactsLocationResolver.Resolve(application);

            var caseArtifacts = _artifactsService.CreateCompressedArchive(caseArtifactsLocation);

            _scheduleRuntimeEvents.CaseFailed(application.SessionId, @case, caseArtifacts);

            await _repository.SaveChangesAsync();
        }
    }
}