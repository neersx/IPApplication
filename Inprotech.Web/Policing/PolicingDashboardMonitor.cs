using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using Inprotech.Infrastructure.Messaging;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using InprotechKaizen.Model.Components.System.Messages;

namespace Inprotech.Web.Policing
{
    public class PolicingDashboardMonitor : IPolicingDashboardMonitor
    {
        readonly IBus _bus;
        readonly IDashboardSubscriptions _dashboardSubscriptions;
        readonly IDashboardDataProvider _dashboardDataProvider;
        readonly ConcurrentDictionary<RetrieveOption, object> _inProgress = new ConcurrentDictionary<RetrieveOption, object>();

        public PolicingDashboardMonitor(IBus bus, IDashboardSubscriptions dashboardSubscriptions, IDashboardDataProvider dashboardDataProvider)
        {
            if (bus == null) throw new ArgumentNullException("bus");
            if (dashboardSubscriptions == null) throw new ArgumentNullException("dashboardSubscriptions");
            if (dashboardDataProvider == null) throw new ArgumentNullException("dashboardDataProvider");

            _bus = bus;
            _dashboardSubscriptions = dashboardSubscriptions;
            _dashboardDataProvider = dashboardDataProvider;
        }

        public void Run()
        {
            var subscriptions = _dashboardSubscriptions.Resolve();

            if (!subscriptions.Any())
                return;

            var option = subscriptions.Trend ? RetrieveOption.WithTrends : RetrieveOption.Default;

            if (!_inProgress.TryAdd(option, null))
                return;

            Dictionary<RetrieveOption, DashboardData> data;
            try
            {
                data = _dashboardDataProvider.Retrieve(option);
            }
            finally
            {
                _inProgress.TryRemove(option, out _);
            }

            if (subscriptions.Trend)
            {
                _bus.Publish(new BroadcastMessageToClient
                {
                    Data = data[RetrieveOption.WithTrends],
                    Topic = SubscriptionTopic.CurrentStateWithTrends
                });
            }

            _bus.Publish(new BroadcastMessageToClient
            {
                Data = data[RetrieveOption.Default],
                Topic = SubscriptionTopic.CurrentState
            });
        }
    }
}