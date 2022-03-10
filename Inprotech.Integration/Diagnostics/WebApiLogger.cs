using System;
using Inprotech.Contracts;
using Inprotech.Infrastructure.DependencyInjection;
using Inprotech.Infrastructure.Security.ExternalApplications;
using InprotechKaizen.Model.Components.Security;
using NLog;

namespace Inprotech.Integration.Diagnostics
{
    public class WebApiLogger<T> : ILogger<T>
    {
        readonly ILifetimeScope _scope;
        readonly Logger _logger;
        
        Guid? _contextId;

        public WebApiLogger(
            ILifetimeScope scope)
        {
            _scope = scope;
            _logger = LogManager.GetLogger(typeof(T).FullName);
        }
        
        public void SetContext(Guid contextId)
        {
            _contextId = contextId;
        }

        public void Trace(string message, object data = null)
        {
            if (!_logger.IsTraceEnabled) return;

            _logger.Log(LogEventInfo.Create(LogLevel.Trace, _logger.Name, message));
        }

        public void Debug(string message, object data = null)
        {
            if (!_logger.IsDebugEnabled) return;

            _logger.Log(LogEventInfo.Create(LogLevel.Debug, _logger.Name, message));
        }

        public void Information(string message, object data = null)
        {
            if (!_logger.IsInfoEnabled) return;

            _logger.Log(LogEventInfo.Create(LogLevel.Info, _logger.Name, message));
        }

        public void Warning(string message, object data = null)
        {
            if (!_logger.IsWarnEnabled) return;

            _logger.Log(LogEventInfo.Create(LogLevel.Warn, _logger.Name, message));
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

        LogEventInfo StandardEvent(Func<LogEventInfo> builder)
        {
            var e = builder();
            
            if (_scope.TryResolve<IExternalApplicationContext>(out var externalApplicationContext))
            {
                e.Properties["ApplicationName"] = externalApplicationContext.ExternalApplicationName;    
            }

            if (_scope.TryResolve<ISecurityContext>(out var securityContext))
            {
                e.Properties["User"] = securityContext.User?.UserName;
            }
            
            if (_contextId != null && _contextId != Guid.Empty)
                e.Properties["RequestId"] = _contextId;

            return e;
        }
    }
}