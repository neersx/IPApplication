using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Extensibility;

#pragma warning disable 1998

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class DueSchedule
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IFileSystem _fileSystem;
        readonly IRepository _repository;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;

        public DueSchedule(IRepository repository,
                           IFileSystem fileSystem,
                           IArtifactsLocationResolver artifactsLocationResolver,
                           IScheduleRuntimeEvents scheduleRuntimeEvents)
        {
            _fileSystem = fileSystem;
            _artifactsLocationResolver = artifactsLocationResolver;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _repository = repository;
        }

        public async Task<Activity> Run(int scheduleId, Guid cancellationToken)
        {
            var schedule = _repository.Set<Schedule>()
                                      .WhereActive()
                                      .Single(s => s.Id == scheduleId);

            var sessionId = _scheduleRuntimeEvents.StartSchedule(schedule, cancellationToken);

            var session = new Session
            {
                ScheduleId = schedule.Id,
                Id = sessionId,
                Name = schedule.Name,
                DownloadActivity = DownloadActivityType.All,
                CustomerNumber = GetCombinedCustomerNumbers()
            };

            _fileSystem.EnsureFolderExists(_artifactsLocationResolver.Resolve(session));

            var validate = BuildValidationActivities(session);

            var runWorkflow = Activity.Run<IMessages>(_ => _.Retrieve(session));
            var runRecoveryWorkflow = Activity.Run<IMessages>(_ => _.RetrieveRecoverable(session));

            var endSession = Activity.Run<IPrivatePairRuntimeEvents>(r => r.EndSession(session));
            var recoveryComplete = Activity.Run<RecoveryComplete>(rc => rc.Complete(scheduleId));

            var workflow = schedule.Type == ScheduleType.Retry
                ? Activity.Sequence(validate, runRecoveryWorkflow, endSession).Cancelled(Activity.Run<RecoveryComplete>(rc => rc.Complete(scheduleId)))
                : Activity.Sequence(validate, runWorkflow, endSession).Cancelled(Activity.Run<DueSchedule>(d => d.CancelExecution(session.Id)));

            var entireWorkflow = workflow
                                 .ExceptionFilter<IPtoFailureLogger>((c, e) => e.LogSessionError(c, session))
                                 .AnyFailed(Activity.Run<IScheduleInitialisationFailure>(s => s.SaveArtifactAndNotify(session)))
                                 .ThenContinue();

            return entireWorkflow;
        }

        string GetCombinedCustomerNumbers()
        {
            var activeSponsoredCustomerNumbers = _repository.NoDeleteSet<Sponsorship>().Select(_ => _.CustomerNumbers).ToArray();

            return string.Join(", ",
                               (from raw in activeSponsoredCustomerNumbers
                                from customerNumber in raw.Split(',')
                                let cn = customerNumber.Trim()
                                where !string.IsNullOrWhiteSpace(cn)
                                select cn).Distinct());
        }

        public Task CancelExecution(Guid sessionId)
        {
            _scheduleRuntimeEvents.Cancel(sessionId);
            return Task.FromResult(0);
        }

        static Activity BuildValidationActivities(Session session)
        {
            var validateRequiredSettings = Activity.Run<IEnsureScheduleValid>(e => e.ValidateRequiredSettings(session));

            var validateBackgroundIdentityConfiguration = Activity.Run<BackgroundIdentityConfiguration>(e => e.ValidateExists());

            return Activity.Sequence(validateRequiredSettings, validateBackgroundIdentityConfiguration);
        }
    }
}