using System;
using System.Net;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Integration.Exchange;
using Microsoft.Exchange.WebServices.Data;

namespace Inprotech.IntegrationServer.ExchangeIntegration.Strategy.Ews
{
    public interface IExchangeServiceConnection
    {
        ExchangeService Get(ExchangeConfigurationSettings setting, string mailbox);
    }

    public class ExchangeServiceConnection : IExchangeServiceConnection
    {
        readonly Func<DateTime> _clock;
        readonly ILogger<ExchangeServiceConnection> _logger;
        readonly Func<string, IGroupedConfig> _groupConfigFunc;

        static DateTime _lastChecked = DateTime.MinValue;
        static bool _shouldTrace;

        public ExchangeServiceConnection(Func<string, IGroupedConfig> groupedConfig, Func<DateTime> clock, ILogger<ExchangeServiceConnection> logger)
        {
            _groupConfigFunc = groupedConfig;
            _clock = clock;
            _logger = logger;
        }

        bool ShouldTrace()
        {
            var now = _clock();

            if (now - _lastChecked > TimeSpan.FromHours(1))
            {
                var ews = _groupConfigFunc("Inprotech.ExchangeIntegration.Ews");
                _shouldTrace = ews.GetValueOrDefault<bool>("TraceEnabled");

                _lastChecked = now;
            }

            return _shouldTrace;
        }
        
        public ExchangeService Get(ExchangeConfigurationSettings setting, string mailbox)
        {
            var service = new ExchangeService(ExchangeVersion.Exchange2010)
            {
                Credentials = new NetworkCredential
                {
                    UserName = setting.UserName,
                    Password = setting.Password,
                    Domain = setting.Domain
                },
                Url = new Uri(setting.Server)
            };

            if (!string.IsNullOrWhiteSpace(mailbox))
            {
                service.ImpersonatedUserId = new ImpersonatedUserId(ConnectingIdType.SmtpAddress, mailbox);
                service.HttpHeaders.Add("X-AnchorMailbox", mailbox);
            }

            if (ShouldTrace())
            {
                service.TraceEnabled = true;
                service.TraceEnablePrettyPrinting = true;
                service.TraceFlags = TraceFlags.All;
                service.TraceListener = new ExchangeTraceListener(_logger);
            }
            
            return service;
        }

        public class ExchangeTraceListener : ITraceListener
        {
            readonly ILogger _logger;

            public ExchangeTraceListener(ILogger logger)
            {
                _logger = logger;
            }

            public void Trace(string traceType, string traceMessage)
            {
                _logger.Trace($"EWS:{traceType}:{Environment.NewLine}{traceMessage}");
            }
        }
    }
}