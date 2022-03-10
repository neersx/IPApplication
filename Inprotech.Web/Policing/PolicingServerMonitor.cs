using System;
using Inprotech.Infrastructure.Messaging;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using InprotechKaizen.Model.Components.System.Messages;

namespace Inprotech.Web.Policing
{
    public class PolicingServerMonitor : IPolicingServerMonitor
    {
        readonly IBus _bus;
        readonly IPolicingBackgroundServer _policingBackgroundServer;
        readonly IDashboardSubscriptions _subscriptions;

        public PolicingServerMonitor(IBus bus, IPolicingBackgroundServer policingBackgroundServer, IDashboardSubscriptions subscriptions)
        {
            if (bus == null) throw new ArgumentNullException("bus");
            if (policingBackgroundServer == null) throw new ArgumentNullException("policingBackgroundServer");

            _bus = bus;
            _policingBackgroundServer = policingBackgroundServer;
            _subscriptions = subscriptions;
        }

        public void Run()
        {
            if (!_subscriptions.PolicingStatusSubscription())
                return;

            var data = _policingBackgroundServer.Status();

            _bus.Publish(new BroadcastMessageToClient
            {
                Data = (int)data,
                Topic = SubscriptionTopic.PolicingServerStatus
            });
        }
    }
}