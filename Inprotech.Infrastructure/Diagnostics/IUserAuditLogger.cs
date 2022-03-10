using System;
using System.Net.Http;
using Inprotech.Contracts;
using Microsoft.Owin;
using NLog;

namespace Inprotech.Infrastructure.Diagnostics
{
    public class NLogUserAuditLogger<T> : IUserAuditLogger<T>
    {
        readonly Logger _logger;
        const string OwinContext = "MS_OwinContext";
        const string IpAddress = "IPAddress";

        public NLogUserAuditLogger()
        {
            _logger = LogManager.GetLogger(typeof (T).FullName);
        }

        public void SetContext(Guid contextId)
        {
            throw new NotImplementedException();
        }

        public void Trace(string message, object data = null)
        {
            var @event = LogEventInfo.Create(LogLevel.Trace, _logger.Name, message);
            @event.Properties[IpAddress] = RemoteIPAddress(data);
            _logger.Log(@event);
        }

        public void Debug(string message, object data = null)
        {
            var @event = LogEventInfo.Create(LogLevel.Debug, _logger.Name, message);
            @event.Properties[IpAddress] = RemoteIPAddress(data);
            _logger.Log(@event);
        }

        public void Information(string message, object data = null)
        {
            var @event = LogEventInfo.Create(LogLevel.Info, _logger.Name, message);
            @event.Properties[IpAddress] = RemoteIPAddress(data);
            _logger.Log(@event);
        }

        public void Warning(string message, object data = null)
        {
            var @event = LogEventInfo.Create(LogLevel.Warn, _logger.Name, message);
            @event.Properties[IpAddress] = RemoteIPAddress(data);
            _logger.Log(@event);
        }

        public void Exception(Exception exception, string message = null)
        {
            var m = string.IsNullOrWhiteSpace(message)
                ? exception.Message
                : $"{message}{Environment.NewLine}{exception.Message}";

            _logger.Log(LogEventInfo.Create(LogLevel.Error, _logger.Name, exception, null, m));
        }

        string RemoteIPAddress(object data)
        {
            if (data is HttpRequestMessage request)
            {
                if (!request.Properties.ContainsKey(OwinContext)) return null;
                return ((OwinContext) request.Properties[OwinContext]).Request.RemoteIpAddress;
            }

            if (data is OwinRequest owinRequest)
            {
                return owinRequest.RemoteIpAddress;
            }

            return null;
        }
    }
}