using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.Names.Consolidations;
using Inprotech.Web.Messaging;
using InprotechKaizen.Model.Components.System.Messages;

namespace Inprotech.Web.Names.Consolidations
{
    public interface INameConsolidationStatusMonitor : IMonitorClockRunnable
    {
    }

    public class NameConsolidationStatusMonitor : INameConsolidationStatusMonitor
    {
        readonly IBus _bus;
        readonly IClientSubscriptions _clientSubscriptions;
        readonly INameConsolidationStatusChecker _statusChecker;

        public NameConsolidationStatusMonitor(IBus bus, IClientSubscriptions clientSubscriptions, INameConsolidationStatusChecker statusChecker)
        {
            _bus = bus;
            _clientSubscriptions = clientSubscriptions;
            _statusChecker = statusChecker;
        }

        public void Run()
        {
            if (!IsSubscribedTo("name.consolidation.status"))
            {
                return;
            }
            
            var status = _statusChecker.GetStatus();

            _bus.Publish(new BroadcastMessageToClient
            {
                Data = status,
                Topic = "name.consolidation.status"
            });
        }

        bool IsSubscribedTo(string topic)
        {
            return _clientSubscriptions
                   .Find(topic, (a, b) => string.Equals(a, b, StringComparison.OrdinalIgnoreCase))
                   .Any();
        }
    }
}