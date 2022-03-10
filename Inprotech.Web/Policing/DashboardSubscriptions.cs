using System;
using System.Linq;
using Inprotech.Web.Messaging;

namespace Inprotech.Web.Policing
{
    public interface IDashboardSubscriptions
    {
        DashboardSubscription Resolve();

        bool PolicingStatusSubscription();
    }

    public class DashboardSubscriptions : IDashboardSubscriptions
    {
        readonly IClientSubscriptions _clientSubscriptions;

        public DashboardSubscriptions(IClientSubscriptions clientSubscriptions)
        {
            if (clientSubscriptions == null) throw new ArgumentNullException("clientSubscriptions");
            _clientSubscriptions = clientSubscriptions;
        }

        public DashboardSubscription Resolve()
        {
            var currentState = IsSubscribedTo(SubscriptionTopic.CurrentState);

            var trends = IsSubscribedTo(SubscriptionTopic.CurrentStateWithTrends);

            return new DashboardSubscription
            {
                CurrentState = currentState || trends,
                Trend = trends
            };
        }

        public bool PolicingStatusSubscription()
        {
            return IsSubscribedTo(SubscriptionTopic.PolicingServerStatus);
        }

        bool IsSubscribedTo(string topic)
        {
            return _clientSubscriptions
                .Find(topic, (a, b) => string.Equals(a, b, StringComparison.OrdinalIgnoreCase))
                .Any();
        }
    }

    public class DashboardSubscription
    {
        public bool CurrentState { get; set; }

        public bool Trend { get; set; }

        public bool Any()
        {
            return CurrentState || Trend;
        }
    }
}