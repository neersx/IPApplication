using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using InprotechKaizen.Model.Components.Policing.Forecast;
using InprotechKaizen.Model.Components.System.Messages;

namespace Inprotech.Web.Policing
{
    public interface IPolicingAffectedCasesMonitor : IMonitorClockRunnable
    {
    }

    internal class PolicingAffectedCasesMonitor : IPolicingAffectedCasesMonitor
    {
        readonly IBus _bus;

        readonly IPolicingRequestSps _policingRequestSps;
        readonly IPolicingAffectedCasesSubscriptions _subscriptions;

        public PolicingAffectedCasesMonitor(IBus bus, IPolicingAffectedCasesSubscriptions subscriptions, IPolicingRequestSps policingRequestSps)
        {
            _bus = bus;
            _subscriptions = subscriptions;
            _policingRequestSps = policingRequestSps;
        }

        public void Run()
        {
            var newRequestIds = _subscriptions.NewRequestids.ToArray();
            if (!newRequestIds.Any())
                return;
            _subscriptions.SetInprogress(newRequestIds);

            foreach (var id in newRequestIds.Distinct())
            {
                var message = new BroadcastMessageToClient
                {
                    Topic = $"policing.affected.cases.{id}",
                    Data = _policingRequestSps.GetNoOfAffectedCases(id)
                };

                _bus.Publish(message);
            }
        }
    }
}