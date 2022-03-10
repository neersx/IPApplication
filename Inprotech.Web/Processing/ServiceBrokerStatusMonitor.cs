using System;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Web.Messaging;
using InprotechKaizen.Model.Components.System;
using InprotechKaizen.Model.Components.System.AsyncCommands;
using InprotechKaizen.Model.Components.System.Messages;

namespace Inprotech.Web.Processing
{
    public interface IServiceBrokerStatusMonitor : IMonitorClockRunnable
    {
    }
    public class ServiceBrokerStatusMonitor : IServiceBrokerStatusMonitor
    {
        readonly IBus _bus;
        readonly IBackgroundProcessLogger<IServiceBrokerStatusMonitor> _logger;
        readonly IClientSubscriptions _clientSubscriptions;
        readonly IServiceBrokerQuery _serviceBrokerQuery;
        internal static bool CurrentServiceBrokerStatus = true;

        const string ServiceBrokerStatus = "processing.backgroundServices.status";

        public ServiceBrokerStatusMonitor(IBus bus, IBackgroundProcessLogger<IServiceBrokerStatusMonitor> logger, IClientSubscriptions clientSubscriptions, IServiceBrokerQuery serviceBrokerQuery)
        {
            _bus = bus;
            _logger = logger;
            _clientSubscriptions = clientSubscriptions;
            _serviceBrokerQuery = serviceBrokerQuery;
        }

        public void Run()
        {
            if (!IsSubscribed())
                return;

            var newStatus = _serviceBrokerQuery.IsEnabled();

            if (CurrentServiceBrokerStatus != newStatus)
            {
                CurrentServiceBrokerStatus = newStatus;

                _logger.Warning($"Service Broker is {(CurrentServiceBrokerStatus ? "Enabled" : "Disabled")} on System {Environment.MachineName}");
            }

            _bus.Publish(new BroadcastMessageToClient
            {
                Data = newStatus,
                Topic = ServiceBrokerStatus
            });

        }

        bool IsSubscribed()
        {
            return _clientSubscriptions
                .Find(ServiceBrokerStatus, (a, b) => string.Equals(a, b, StringComparison.OrdinalIgnoreCase))
                .Any();
        }
    }
}
