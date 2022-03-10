using System;
using System.Collections.Generic;
using System.Linq;
using Dependable;
using Dependable.Tracking;
using Inprotech.Tests.Dependable;
using Newtonsoft.Json;

namespace Inprotech.Tests.Extensions
{
    public class JobStatusEventLogger : IEventSink
    {
        readonly Dictionary<EventType, Formatter> _formatterMappers;
        readonly SimpleLogger _simpleLogger;

        public JobStatusEventLogger(SimpleLogger simpleLogger, bool detailedLog)
        {
            _simpleLogger = simpleLogger;

            var statusChangeToLog = detailedLog
                ? new JobStatus[0]
                : new[] {JobStatus.Failed, JobStatus.Running, JobStatus.Poisoned, JobStatus.Cancelled};

            var statusChangedFormatter = new StatusChangeFormatter(statusChangeToLog);
            var exceptionFormatter = new ExceptionFormatter(detailedLog);
            var jsonFormatter = new JsonFormatter();

            _formatterMappers = new Dictionary<EventType, Formatter>
                {
                    {EventType.JobStatusChanged, statusChangedFormatter},
                    {EventType.Exception, exceptionFormatter},
                    {EventType.JobCancelled, jsonFormatter}
                };
        }

        public void Dispatch(EventType type, Dictionary<string, object> data)
        {
            if (!_formatterMappers.TryGetValue(type, out var formatter)) return;

            var formatted = formatter.Format(data);
            if (!string.IsNullOrWhiteSpace(formatted))
            {
                _simpleLogger.Log(type, formatted);
            }
        }

        public class StatusChangeFormatter : Formatter
        {
            readonly JobStatus[] _allowedToStatus;

            public StatusChangeFormatter(IEnumerable<JobStatus> statusesToLog)
            {
                _allowedToStatus = statusesToLog.ToArray();
            }

            static int LongestStatus => Enum.GetNames(typeof(JobStatus)).Max(_ => _.Length);

            public override string Format(Dictionary<string, object> data)
            {
                var fromStatus = (JobStatus)data["FromStatus"];
                var toStatus = (JobStatus)data["ToStatus"];
                var jobSnapshot = (JobSnapshot)data["JobSnapshot"];

                if (_allowedToStatus.Any() && !_allowedToStatus.Contains(toStatus))
                {
                    return null;
                }

                return $"{FormatJobStatusTransition(fromStatus, toStatus)}: {jobSnapshot.Type.Name}.{jobSnapshot.Method} (#{jobSnapshot.DispatchCount})";
            }

            static string FormatJobStatusTransition(JobStatus from, JobStatus to)
            {
                var length = LongestStatus;

                return from.ToString().PadRight(length, ' ') + " => " + to.ToString().PadRight(length, ' ');
            }
        }

        public class ExceptionFormatter : Formatter
        {
            readonly bool _detailed;

            public ExceptionFormatter(bool detailed)
            {
                _detailed = detailed;
            }

            public override string Format(Dictionary<string, object> data)
            {
                var exception = (Exception)data["Exception"];
                if (exception.InnerException != null)
                {
                    exception = exception.InnerException;
                }

                return _detailed
                    ? $"{exception}"
                    : $"{exception.Message}";
            }
        }

        public class JsonFormatter : Formatter
        {
            public override string Format(Dictionary<string, object> data)
            {
                return JsonConvert.SerializeObject(data, Formatting.Indented);
            }
        }

        public abstract class Formatter
        {
            public abstract string Format(Dictionary<string, object> data);
        }
    }
}