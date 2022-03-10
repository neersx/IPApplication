using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Integration.Schedules.Extensions.Uspto.Tsdr;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.IntegrationServer.PtoAccess.Recovery;

#pragma warning disable CS1998 // Async "Run" method lacks 'await' operators and will run synchronously

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class DueSchedule
    {
        readonly IRepository _repository;
        readonly IFileSystem _fileSystem;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;

        public DueSchedule(IRepository repository, IFileSystem fileSystem, IScheduleRuntimeEvents scheduleRuntimeEvents,
            IDataDownloadLocationResolver dataDownloadLocationResolver)
        {
            _repository = repository;
            _fileSystem = fileSystem;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
        }

        public Task CancelRun(DataDownload dataDownloadSession)
        {
            if (dataDownloadSession == null) throw new ArgumentNullException(nameof(dataDownloadSession));

            _scheduleRuntimeEvents.Cancel(dataDownloadSession.Id);

            return Task.FromResult(0);
        }

        //Kept for legacy rehydration 
        public async Task<Activity> Run(int scheduleId)
        {
            return await Execute(scheduleId, Guid.Empty);
        }

        public async Task<Activity> Execute(int scheduleId, Guid cancellationToken)
        {
            var schedule = _repository.Set<Schedule>().WhereActive().Single(s => s.Id == scheduleId);
            
            var tsdrSchedule = schedule.GetExtendedSettings<TsdrSchedule>();

            var sessionId = _scheduleRuntimeEvents.StartSchedule(schedule, cancellationToken);

            var dataDownloadSession = new DataDownload
                                      {
                                          ScheduleId = schedule.Id,
                                          DataSourceType = schedule.DataSourceType,
                                          Name = schedule.Name,
                                          Id = sessionId,
                                          DownloadType = schedule.DownloadType
                                      };

            _fileSystem.EnsureFolderExists(_dataDownloadLocationResolver.Resolve(dataDownloadSession));

            var runWorkflow =
                Activity.Run<ResolveEligibleCases>(
                    _ => _.From(dataDownloadSession, tsdrSchedule.SavedQueryId.Value, tsdrSchedule.RunAsUserId.Value));

            var endSession =
                Activity.Run<RuntimeEvents>(r => r.EndSession(dataDownloadSession));

            var recoveryCompleteActivity = Activity.Run<RecoveryComplete>(rc => rc.Complete(scheduleId));
            var recoveryComplete = recoveryCompleteActivity.Cancelled(Activity.Run<RecoveryComplete>(rc => rc.Complete(scheduleId)));

            var validate = BuildValidationActivities(tsdrSchedule);

            var workflow = schedule.Type == ScheduleType.Retry
                ? Activity.Sequence(validate, runWorkflow, endSession, recoveryComplete)
                : Activity.Sequence(validate, runWorkflow, endSession);

            return workflow
                .Cancelled(Activity.Run<DueSchedule>(d => d.CancelRun(dataDownloadSession)))
                .ExceptionFilter<ErrorLogger>((c, e) => e.Log(c, dataDownloadSession))
                .AnyFailed(Activity.Run<ScheduleInitialisationFailure>(s => s.Notify(dataDownloadSession)))
                .ThenContinue();
        }
        
        static Activity BuildValidationActivities(TsdrSchedule tsdrSchedule)
        {
            var validateRequiredSettings = Activity.Run<EnsureScheduleValid>(e => e.ValidateRequiredSettings(tsdrSchedule));

            var validateBackgroundIdentityConfiguration = Activity.Run<BackgroundIdentityConfiguration>(e => e.ValidateExists());

            return Activity.Sequence(
                                     validateRequiredSettings, validateBackgroundIdentityConfiguration
                                    );
        }
    }
}