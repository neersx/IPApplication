using System;
using System.Text;
using System.Xml.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Newtonsoft.Json;
using NLog;

namespace Inprotech.Infrastructure.Diagnostics
{
    public class NLogLogger<T> : ILogger<T>
    {
        readonly Logger _logger;
        readonly ICurrentUser _currentUser;
        readonly IRequestContext _requestContext;

        Guid? _requestContextId = null;

        public void SetContext(Guid contextId) => _requestContextId = contextId;

        public NLogLogger(ICurrentUser currentUser, IRequestContext requestContext)
        {
            _currentUser = currentUser;
            _requestContext = requestContext;

            _logger = LogManager.GetLogger(typeof(T).FullName);
        }

        public void Trace(string message, object data = null)
        {
            Log(LogLevel.Trace, message, data);
        }

        public void Debug(string message, object data = null)
        {
            Log(LogLevel.Debug, message, data);
        }

        public void Information(string message, object data = null)
        {
            Log(LogLevel.Info, message, data);
        }

        public void Warning(string message, object data = null)
        {
            Log(LogLevel.Warn, message, data);
        }

        public void Exception(Exception exception, string message = null)
        {
            if (exception == null) throw new ArgumentNullException(nameof(exception));

            var m = string.IsNullOrWhiteSpace(message)
                ? exception.Message
                : $"{message}{Environment.NewLine}{exception.Message}";

            var @event =
                StandardEvent(() => LogEventInfo.Create(LogLevel.Error, _logger.Name, exception, null, m));

            foreach (var key in exception.Data.Keys)
                @event.Properties[key] = exception.Data[key];

            _logger.Log(@event);
        }

        void Log(LogLevel level, string message, object data)
        {
            if (!_logger.IsEnabled(level))
                return;

            if (string.IsNullOrWhiteSpace(message)) throw new ArgumentException("A valid message is required.");

            var @event = StandardEvent(() => LogEventInfo.Create(level, _logger.Name, message));

            if (data != null)
            {
                var ai = new StringBuilder().AppendLine().AppendLine("===Begin===");

                if (!string.IsNullOrWhiteSpace(data as string))
                {
                    ai.AppendLine((string) data);
                }
                else if (data is XElement element)
                {
                    ai.AppendLine(element.ToString(SaveOptions.None));
                }
                else
                {
                    ai.AppendLine(JsonConvert.SerializeObject(data, Newtonsoft.Json.Formatting.Indented, 
                                                              new JsonSerializerSettings
                                                              {
                                                                  ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
                                                                  MaxDepth = 3
                                                              }));
                }
                ai.AppendLine("===End===");

                @event.Properties["AdditionalInformation"] = ai.ToString();
            }

            _logger.Log(@event);
        }

        LogEventInfo StandardEvent(Func<LogEventInfo> builder)
        {
            var e = builder();
            
            try
            {
                e.Properties["User"] = _currentUser.Identity != null ? _currentUser.Identity.Name : string.Empty;
                e.Properties["RequestId"] = _requestContextId ?? _requestContext.RequestId;

                if (_requestContext.Request == null)
                {
                    return e;
                }

                e.Properties["Url"] = _requestContext.Request.RequestUri.AbsoluteUri;
            }
            catch
            {

            }

            return e;
        }
    }
}