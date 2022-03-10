using System;
using System.Linq;
using Dependable.Diagnostics;
using Dependable.Dispatcher;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.Scheduling
{
    public class SchedulePreInitialisationFailed
    {
        readonly ILogEntry _logEntry;
        readonly IRepository _repository;
        readonly Func<DateTime> _now;
        readonly ScheduleExecutionResolver _scheduleExecutionResolver;

        public SchedulePreInitialisationFailed(ILogEntry logEntry, IRepository repository, Func<DateTime> now, ScheduleExecutionResolver scheduleExecutionResolver)
        {
            _logEntry = logEntry;
            _repository = repository;
            _now = now;
            _scheduleExecutionResolver = scheduleExecutionResolver;
        }

        public void Log(ExceptionContext exceptionContext, int scheduleId, Guid cancellationToken)
        {
            if (exceptionContext.Method != "Run" || !DueScheduleActivities.List.Contains(exceptionContext.ActivityType))
                return;

            var schedule = _repository.Set<Schedule>().Single(s => s.Id == scheduleId);

            var logEntry = JsonConvert.SerializeObject(new[] {_logEntry.Create(exceptionContext)});

            var scheduleExecution = _scheduleExecutionResolver.Resolve(scheduleId, cancellationToken);

            _repository.Set<ScheduleFailure>().Add(new ScheduleFailure(schedule, scheduleExecution, _now(), logEntry));

            _repository.SaveChanges();
        }
    }

    public class ExceptionLogger : IExceptionLogger
    {
        readonly IDataExtractionLogger _dataExtractionLogger;

        public ExceptionLogger(IDataExtractionLogger dataExtractionLogger)
        {
            _dataExtractionLogger = dataExtractionLogger;
        }

        public void Log(Exception exception)
        {
            _dataExtractionLogger.Exception(exception);
        }
    }
}