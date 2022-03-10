using System;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Web.Messaging;
using Inprotech.Web.Processing;
using InprotechKaizen.Model.Components.System;
using InprotechKaizen.Model.Components.System.AsyncCommands;
using InprotechKaizen.Model.Components.System.Messages;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Processing
{
    public class ServiceBrokerStatusMonitorFacts
    {
        const string Topic = "processing.backgroundServices.status";

        class ServiceBrokerStatusMonitorFactsFixture : IFixture<IServiceBrokerStatusMonitor>
        {
            public ServiceBrokerStatusMonitorFactsFixture()
            {
                Bus = Substitute.For<IBus>();
                ClientSubscriptions = Substitute.For<IClientSubscriptions>();
                Query = Substitute.For<IServiceBrokerQuery>();
                Logger = Substitute.For<IBackgroundProcessLogger<IServiceBrokerStatusMonitor>>();
                Subject = new ServiceBrokerStatusMonitor(Bus, Logger, ClientSubscriptions, Query);
                ServiceBrokerStatusMonitor.CurrentServiceBrokerStatus = true;
            }

            public IBus Bus { get; }
            public IClientSubscriptions ClientSubscriptions { get; }
            public IServiceBrokerQuery Query { get; }

            public IBackgroundProcessLogger<IServiceBrokerStatusMonitor> Logger { get; }
            public IServiceBrokerStatusMonitor Subject { get; }

            public ServiceBrokerStatusMonitorFactsFixture WithServiceBroker(bool isEnabled)
            {
                Query.IsEnabled().ReturnsForAnyArgs(isEnabled);
                return this;
            }

            public ServiceBrokerStatusMonitorFactsFixture WithSubscription(bool hasSubscriptions)
            {
                var str = hasSubscriptions ? new[] {Fixture.String()} : new string[0];
                ClientSubscriptions.Find(Topic, Arg.Any<Func<string, string, bool>>()).Returns(str);
                return this;
            }
        }

        [Fact]
        public void RunShouldCallQuery()
        {
            var f = new ServiceBrokerStatusMonitorFactsFixture().WithSubscription(true);

            f.Subject.Run();

            f.Query.Received(1).IsEnabled();

            f.Bus.Received(1).Publish(Arg.Do<BroadcastMessageToClient>(publishedMessage =>
            {
                Assert.Equal(Topic, publishedMessage.Topic);
                Assert.False((bool) publishedMessage.Data);
            }));
        }

        [Fact]
        public void RunShouldLogOnceForEachStatusChange()
        {
            var f = new ServiceBrokerStatusMonitorFactsFixture().WithSubscription(true).WithServiceBroker(false);

            f.Subject.Run();
            AssertLogMessage("Disabled");
            AssertPublishMessage(false);
            ClearCalls();

            AssertRunMultipleTimesWithoutLog(false);

            f.WithServiceBroker(true);
            f.Subject.Run();
            AssertLogMessage("Enabled");
            AssertPublishMessage(true);
            ClearCalls();

            AssertRunMultipleTimesWithoutLog(true);

            void AssertLogMessage(string message)
            {
                f.Logger.Received(1).Warning(Arg.Do<string>(m => { Assert.Contains(message, m); }));
            }

            void AssertPublishMessage(bool isEnabled)
            {
                f.Bus.Received(1).Publish(Arg.Do<BroadcastMessageToClient>(publishedMessage =>
                {
                    Assert.Equal(Topic, publishedMessage.Topic);
                    Assert.Equal(isEnabled, (bool) publishedMessage.Data);
                }));
            }

            void AssertRunMultipleTimesWithoutLog(bool isEnabled)
            {
                for (var i = 0; i < 3; i++)
                {
                    f.Subject.Run();
                    f.Logger.DidNotReceive().Warning(Arg.Any<string>());
                    AssertPublishMessage(isEnabled);
                    ClearCalls();
                }
            }

            void ClearCalls()
            {
                f.Logger.ClearReceivedCalls();
                f.Bus.ClearReceivedCalls();
            }
        }

        [Fact]
        public void RunShouldNotCallQueryIfNoSubscription()
        {
            var f = new ServiceBrokerStatusMonitorFactsFixture().WithSubscription(false);

            f.Subject.Run();

            f.Query.DidNotReceive().IsEnabled();
            f.Bus.DidNotReceive().Publish(Arg.Any<BroadcastMessageToClient>());
        }
    }
}