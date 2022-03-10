using System;
using Inprotech.Web.Messaging;
using Inprotech.Web.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class DashboardSubscriptionsFacts
    {
        public class ResolveMethod
        {
            [Fact]
            public void ReturnNoSubscriptions()
            {
                var f = new DashboardSubscriptionsFixture()
                    .WithSubscriptionToTopic("a");

                var r = f.Subject.Resolve();

                Assert.False(r.Any());
                Assert.False(r.CurrentState);
                Assert.False(r.Trend);
            }

            [Fact]
            public void ReturnSubscribedToState()
            {
                var f = new DashboardSubscriptionsFixture()
                    .WithSubscriptionToTopic(SubscriptionTopic.CurrentState);

                var r = f.Subject.Resolve();

                Assert.True(r.Any());
                Assert.True(r.CurrentState);
                Assert.False(r.Trend);
            }

            [Fact]
            public void ReturnSubscribedToTrend()
            {
                var f = new DashboardSubscriptionsFixture()
                    .WithSubscriptionToTopic(SubscriptionTopic.CurrentStateWithTrends);

                var r = f.Subject.Resolve();

                Assert.True(r.Any());
                Assert.True(r.CurrentState, "Trend subscription ensures Current state is also subscribed.");
                Assert.True(r.Trend);
            }
        }

        public class DashboardSubscriptionsFixture : IFixture<DashboardSubscriptions>
        {
            public DashboardSubscriptionsFixture()
            {
                ClientSubscriptions = Substitute.For<IClientSubscriptions>();

                Subject = new DashboardSubscriptions(ClientSubscriptions);
            }

            public IClientSubscriptions ClientSubscriptions { get; set; }

            public DashboardSubscriptions Subject { get; set; }

            public DashboardSubscriptionsFixture WithSubscriptionToTopic(string topic)
            {
                ClientSubscriptions
                    .Find(topic, Arg.Any<Func<string, string, bool>>())
                    .Returns(new[] {"this message is subscribed"});

                return this;
            }
        }
    }
}