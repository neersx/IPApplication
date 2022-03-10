using System;
using System.Collections;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Xml.Linq;
using Inprotech.Contracts;
using Newtonsoft.Json;
using NLog;

namespace Inprotech.Infrastructure.Diagnostics
{
    public class NLogBackgroundProcessLogger<T> : IBackgroundProcessLogger<T>
    {
        readonly Logger _logger;
        
        Guid? _contextId;

        public NLogBackgroundProcessLogger()
        {
            _logger = LogManager.GetLogger(typeof (T).FullName);
        }

        public void SetContext(Guid contextId)
        {
            _contextId = contextId;
        }

        public void Trace(string message, object data = null)
        {
            var @event = LogEventInfo.Create(LogLevel.Trace, _logger.Name, message);

            var details = LogData(data);
            if (!string.IsNullOrWhiteSpace(details))
                @event.Properties["AdditionalInformation"] = details;

            if (_contextId != null && _contextId != Guid.Empty)
                @event.Properties["RequestId"] = _contextId;

            _logger.Log(@event);
        }

        public void Debug(string message, object data = null)
        {
            var @event = LogEventInfo.Create(LogLevel.Debug, _logger.Name, message);

            var details = LogData(data);
            if (!string.IsNullOrWhiteSpace(details))
                @event.Properties["AdditionalInformation"] = details;
            
            if (_contextId != null && _contextId != Guid.Empty)
                @event.Properties["RequestId"] = _contextId;

            _logger.Log(@event);
        }

        public void Information(string message, object data = null)
        {
            var @event = LogEventInfo.Create(LogLevel.Info, _logger.Name, message);

            var details = LogData(data);
            if (!string.IsNullOrWhiteSpace(details))
                @event.Properties["AdditionalInformation"] = details;
            
            if (_contextId != null && _contextId != Guid.Empty)
                @event.Properties["RequestId"] = _contextId;

            _logger.Log(@event);
        }

        public void Warning(string message, object data = null)
        {
            var @event = LogEventInfo.Create(LogLevel.Warn, _logger.Name, message);

            var details = LogData(data);
            if (!string.IsNullOrWhiteSpace(details))
                @event.Properties["AdditionalInformation"] = details;
            
            if (_contextId != null && _contextId != Guid.Empty)
                @event.Properties["RequestId"] = _contextId;

            _logger.Log(@event);
        }

        public void Exception(Exception exception, string message = null)
        {
            var m = string.IsNullOrWhiteSpace(message)
                ? exception.Message
                : $"{message}{Environment.NewLine}{exception.Message}";

            var @event = LogEventInfo.Create(LogLevel.Error, _logger.Name, exception, null, m);

            if (_contextId != null && _contextId != Guid.Empty)
                @event.Properties["RequestId"] = _contextId;

            _logger.Log(@event);
        }

        static string LogData(object data = null)
        {
            if (data == null) return null;

            const BindingFlags flags = BindingFlags.Public | BindingFlags.Instance | BindingFlags.NonPublic;

            var ai = new StringBuilder("===Begin===").AppendLine();

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
                ai.AppendLine(JsonConvert.SerializeObject(data, Newtonsoft.Json.Formatting.Indented));
            }

            ai.AppendLine("===End===");
            return ai.ToString();
        }
    }
}