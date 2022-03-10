using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Web;
using Dependable.Dispatcher;
using Inprotech.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public enum LogEntryCategory
    {
        Error,
        PtoAccessError,
        DmsIntegrationError
    }

    public interface ILogEntry
    {
        void Create(ExceptionContext context, string path, LogEntryCategory category = LogEntryCategory.Error);

        JObject Create(ExceptionContext context, LogEntryCategory category = LogEntryCategory.Error);
    }

    public class LogEntry : ILogEntry
    {
        readonly IFileSystem _fileSystem;
        readonly Func<DateTime> _now;

        public LogEntry(IFileSystem fileSystem, Func<DateTime> now)
        {
            if (fileSystem == null) throw new ArgumentNullException("fileSystem");
            if (now == null) throw new ArgumentNullException("now");

            _fileSystem = fileSystem;
            _now = now;
        }

        public void Create(ExceptionContext context, string path, LogEntryCategory category = LogEntryCategory.Error)
        {
            CreateInternal(context, path, category);
        }

        public JObject Create(ExceptionContext context, LogEntryCategory category = LogEntryCategory.Error)
        {
            return CreateInternal(context, null, category);
        }

        JObject CreateInternal(ExceptionContext context, string path, LogEntryCategory category)
        {
            var aex = context.Exception as AggregateException;
            var exceptions =
                (aex == null ? BuildExceptionInfo(context.Exception) : aex.Flatten().InnerExceptions).ToArray();

            var essential = exceptions.Where(_ => _.GetType() != typeof(TargetInvocationException)).ToArray();
            exceptions = !essential.Any() ? exceptions : essential;

            var first = exceptions.First();
            var data = HandleExceptionData(first, path);

            var details = JsonConvert.SerializeObject(
                                                      new
                                                      {
                                                          Type = "Error",
                                                          Category = category.ToString(),
                                                          context.ActivityType,
                                                          context.Method,
                                                          context.Arguments,
                                                          first.Message,
                                                          data,
                                                          ExceptionType = first.GetType().ToString(),
                                                          ExceptionDetails =
                                                              exceptions.Select(e => new {Type = e.GetType().ToString(), e.Message, Details = e.StackTrace}),
                                                          DispatchCycle = context.DispatchCount,
                                                          Date = _now()
                                                      }, new JsonSerializerSettings
                                                      {
                                                          ContractResolver = new CamelCasePropertyNamesContractResolver()
                                                      });

            if (!string.IsNullOrWhiteSpace(path))
            {
                _fileSystem.WriteAllText(path, details);
            }

            return JObject.Parse(details);
        }

        IEnumerable<Exception> BuildExceptionInfo(Exception ex)
        {
            yield return ex;

            var inner = ex.InnerException;
            while (inner != null)
            {
                yield return inner;

                inner = inner.InnerException;
            }
        }

        Dictionary<string, object> HandleExceptionData(Exception first, string path)
        {
            var data = new Dictionary<string, object>();

            var h1 = first as HttpException;
            if (h1 != null)
            {
                data["StatusCode"] = string.Format("{0}", h1.GetHttpCode());
                return data;
            }

            var h2 = first as HandlerExpectationFailureException;
            if (h2 == null || string.IsNullOrWhiteSpace(h2.AdditionalData)) return data;

            if (string.IsNullOrWhiteSpace(path))
                return data;

            var infoPath = path.Replace(".log", ".data.txt");
            _fileSystem.WriteAllText(infoPath, h2.AdditionalData);

            data["additionalInfo"] = infoPath;
            return data;
        }
    }

    public static class LogEntryExtension
    {
        public static string NewLog(this ILogEntry logEntry, string logPath = "Logs")
        {
            return Path.Combine(logPath, Guid.NewGuid() + ".log");
        }

        public static string NewContextLog(this ILogEntry logEntry, string context, string logPath = "Logs")
        {
            var c = string.IsNullOrEmpty(context) ? string.Empty : context + "-";

            return Path.Combine(logPath, c + Guid.NewGuid() + ".log");
        }
    }
}