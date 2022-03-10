using System.Collections.Generic;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Components.System.Messages;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingDashboardMonitorFacts
    {
        public class RunMethod
        {
            [Fact]
            public void SendStateDataAlways()
            {
                var f = new PolicingDashboardMonitorFixture();
                f.DashboardSubscriptions.Resolve().Returns(
                                                           new DashboardSubscription
                                                           {
                                                               Trend = false,
                                                               CurrentState = true
                                                           });

                f.Subject.Run();

                f.Bus.DidNotReceive().Publish(
                                              Arg.Is<BroadcastMessageToClient>(_ => _.Topic == SubscriptionTopic.CurrentStateWithTrends));

                f.Bus.Received(1).Publish(
                                          Arg.Is<BroadcastMessageToClient>(_ => _.Topic == SubscriptionTopic.CurrentState));
            }

            [Fact]
            public void SenTrendDataWhereRequired()
            {
                var f = new PolicingDashboardMonitorFixture();
                f.DashboardSubscriptions.Resolve().Returns(
                                                           new DashboardSubscription
                                                           {
                                                               Trend = true,
                                                               CurrentState = true
                                                           });

                f.Subject.Run();

                f.Bus.Received(1).Publish(
                                          Arg.Is<BroadcastMessageToClient>(_ => _.Topic == SubscriptionTopic.CurrentStateWithTrends));

                f.Bus.Received(1).Publish(
                                          Arg.Is<BroadcastMessageToClient>(_ => _.Topic == SubscriptionTopic.CurrentState));
            }

            [Fact]
            public void ShouldNotSendTrendDataWhenNotRequired()
            {
                var f = new PolicingDashboardMonitorFixture();
                f.DashboardSubscriptions.Resolve().Returns(
                                                           new DashboardSubscription
                                                           {
                                                               Trend = false,
                                                               CurrentState = true
                                                           });

                f.Subject.Run();

                f.Bus.DidNotReceive().Publish(
                                              Arg.Is<BroadcastMessageToClient>(_ => _.Topic == SubscriptionTopic.CurrentStateWithTrends));

                f.Bus.Received(1).Publish(
                                          Arg.Is<BroadcastMessageToClient>(_ => _.Topic == SubscriptionTopic.CurrentState));
            }

            [Fact]
            public void WillNotRetrieveDataWhenNoOneIsSubscribed()
            {
                var f = new PolicingDashboardMonitorFixture();
                f.DashboardSubscriptions.Resolve().Returns(new DashboardSubscription());

                f.Subject.Run();

                f.DashboardDataProvider.DidNotReceive().Retrieve(Arg.Any<RetrieveOption>());
            }

            [Fact]
            public void WillRetrieveStateDataWhenSomeOneIsSubscribed()
            {
                var f = new PolicingDashboardMonitorFixture();
                f.DashboardSubscriptions.Resolve().Returns(
                                                           new DashboardSubscription
                                                           {
                                                               Trend = false,
                                                               CurrentState = true
                                                           });

                f.Subject.Run();

                f.DashboardDataProvider.Received(1).Retrieve(RetrieveOption.Default);
            }

            [Fact]
            public void WillRetrieveTrendDataWhenSomeOneIsSubscribed()
            {
                var f = new PolicingDashboardMonitorFixture();
                f.DashboardSubscriptions.Resolve().Returns(
                                                           new DashboardSubscription
                                                           {
                                                               CurrentState = true,
                                                               Trend = true
                                                           });

                f.Subject.Run();

                f.DashboardDataProvider.Received(1).Retrieve(RetrieveOption.WithTrends);
            }
        }

        public class PolicingDashboardMonitorFixture : IFixture<PolicingDashboardMonitor>
        {
            public PolicingDashboardMonitorFixture()
            {
                Bus = Substitute.For<IBus>();

                DashboardDataProvider = Substitute.For<IDashboardDataProvider>();
                DashboardDataProvider.Retrieve(Arg.Any<RetrieveOption>())
                                     .Returns(new Dictionary<RetrieveOption, DashboardData>
                                     {
                                         {RetrieveOption.Default, new DashboardData()},
                                         {RetrieveOption.WithTrends, new DashboardData()}
                                     });

                DashboardSubscriptions = Substitute.For<IDashboardSubscriptions>();

                Subject = new PolicingDashboardMonitor(Bus, DashboardSubscriptions, DashboardDataProvider);
            }

            public IBus Bus { get; set; }

            public IDashboardSubscriptions DashboardSubscriptions { get; set; }

            public IDashboardDataProvider DashboardDataProvider { get; set; }

            public PolicingDashboardMonitor Subject { get; set; }
        }
    }
}