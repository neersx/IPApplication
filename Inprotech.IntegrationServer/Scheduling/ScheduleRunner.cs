using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.Scheduling
{
    public interface IScheduleRunner
    {
        void Run(Schedule schedule);
        void StopScheduleExecutions(int scheduleId, int userId, string userName);
        bool IsReady { get; }
    }

    public class ScheduleRunner : IScheduleRunner
    {
        readonly Func<DateTime> _now;
        readonly IRepository _repository;

        readonly Dictionary<DataSourceType, Action<int, Guid>> _run =
            new Dictionary<DataSourceType, Action<int, Guid>>
            {
                {DataSourceType.UsptoPrivatePair, RunUsptoPrivatePairSchedule},
                {DataSourceType.UsptoTsdr, RunTsdrSchedule},
                {DataSourceType.Epo, RunEpoSchedule},
                {DataSourceType.IpOneData, RunInnographySchedule},
                {DataSourceType.File, RunFileAppSchedule}
            };

        readonly Func<Guid> _tokenGen;

        public ScheduleRunner(IRepository repository, Func<Guid> tokenGen, Func<DateTime> now)
        {
            _repository = repository;
            _tokenGen = tokenGen;
            _now = now;
        }

        public bool IsReady => Configuration.Scheduler != null;

        public void Run(Schedule schedule)
        {
            if (schedule == null) throw new ArgumentNullException(nameof(schedule));

            _run[schedule.DataSourceType](schedule.Id, _tokenGen());
        }

        public void StopScheduleExecutions(int scheduleId, int userId, string userName)
        {
            var executionsStopped = false;
            var cancellableExecutions = _repository.Set<ScheduleExecution>()
                                                   .Include(_ => _.Schedule)
                                                   .Where(s => (s.Schedule.Id == scheduleId || s.Schedule.ParentId == scheduleId) && s.CancellationData != null && s.Status == ScheduleExecutionStatus.Started)
                                                   .ToArray();

            foreach (var scheduleExec in cancellableExecutions)
            {
                var cancellationData = JsonConvert.DeserializeObject<CancellationInfo>(scheduleExec.CancellationData);

                if (!Configuration.Scheduler.Stop(cancellationData.Token))
                {
                    continue;
                }

                cancellationData.ByUserId = userId;
                cancellationData.ByUserName = userName;
                cancellationData.CancelledOn = _now();
                scheduleExec.CancellationData = JsonConvert.SerializeObject(cancellationData);
                scheduleExec.Status = ScheduleExecutionStatus.Cancelling;
                executionsStopped = true;
            }

            if (executionsStopped)
            {
                _repository.SaveChanges();
            }
        }

        static void RunUsptoPrivatePairSchedule(int scheduleId, Guid cancellationToken)
        {
            Configuration.Scheduler.Schedule(
                                             Activity.Run<PtoAccess.Uspto.PrivatePair.Activities.DueSchedule>(a => a.Run(scheduleId, cancellationToken))
                                                     .ExceptionFilter<SchedulePreInitialisationFailed>((c, e) => e.Log(c, scheduleId, cancellationToken))
                                                     .Failed(Activity.Run<PreinitialisationFailureHandler>(_ => _.Terminate(scheduleId, cancellationToken))), cancellationToken);
        }

        static void RunTsdrSchedule(int scheduleId, Guid cancellationToken)
        {
            Configuration.Scheduler.Schedule(
                                             Activity.Run<PtoAccess.Uspto.Tsdr.Activities.DueSchedule>(a => a.Execute(scheduleId, cancellationToken))
                                                     .ExceptionFilter<SchedulePreInitialisationFailed>((c, e) => e.Log(c, scheduleId, cancellationToken))
                                                     .Failed(Activity.Run<PreinitialisationFailureHandler>(_ => _.Terminate(scheduleId, cancellationToken))), cancellationToken);
        }

        static void RunEpoSchedule(int scheduleId, Guid cancellationToken)
        {
            Configuration.Scheduler.Schedule(
                                             Activity.Run<PtoAccess.Epo.Activities.DueSchedule>(a => a.Execute(scheduleId, cancellationToken))
                                                     .ExceptionFilter<SchedulePreInitialisationFailed>((c, e) => e.Log(c, scheduleId, cancellationToken))
                                                     .Failed(Activity.Run<PreinitialisationFailureHandler>(_ => _.Terminate(scheduleId, cancellationToken))), cancellationToken);
        }

        static void RunInnographySchedule(int scheduleId, Guid cancellationToken)
        {
            Configuration.Scheduler.Schedule(
                                             Activity.Run<PtoAccess.Innography.Activities.DueSchedule>(a => a.Execute(scheduleId, cancellationToken))
                                                     .ExceptionFilter<SchedulePreInitialisationFailed>((c, e) => e.Log(c, scheduleId, cancellationToken))
                                                     .Failed(Activity.Run<PreinitialisationFailureHandler>(_ => _.Terminate(scheduleId, cancellationToken))), cancellationToken);
        }

        static void RunFileAppSchedule(int scheduleId, Guid cancellationToken)
        {
            Configuration.Scheduler.Schedule(
                                             Activity.Run<PtoAccess.FileApp.Activities.DueSchedule>(a => a.Execute(scheduleId, cancellationToken))
                                                     .ExceptionFilter<SchedulePreInitialisationFailed>((c, e) => e.Log(c, scheduleId, cancellationToken))
                                                     .Failed(Activity.Run<PreinitialisationFailureHandler>(_ => _.Terminate(scheduleId, cancellationToken))), cancellationToken);
        }
    }
}