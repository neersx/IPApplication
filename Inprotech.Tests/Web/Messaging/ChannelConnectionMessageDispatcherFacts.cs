using Inprotech.Contracts.Messages.Channel;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Web.Messaging;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Messaging
{
    public class ChannelConnectionMessageDispatcherFacts
    {
        public ChannelConnectionMessageDispatcherFacts()
        {
            _bus = Substitute.For<IBus>();
            _dispatcher = new ChannelEventDispatcher(_bus);
        }

        readonly IBus _bus;
        readonly ChannelEventDispatcher _dispatcher;
        const int CaseId = -487;
        const int IdentityId = 45;

        [Fact]
        public void GlobalNameChangeSubscribedMessage_Publish()
        {
            var message = new ChannelConnectedMessage
            {
                ConnectionId = Fixture.String(),
                Bindings = new[] {"globalName.change." + CaseId, "others"}
            };

            _dispatcher.Handle(message);

            _bus.Received(1).Publish(Arg.Do<GlobalNameChangeSubscribedMessage>(publishedMessage =>
            {
                Assert.Equal(message.ConnectionId, publishedMessage.ConnectionId);
                Assert.Equal(CaseId, publishedMessage.CaseId);
            }));
        }

        [Fact]
        public void GlobalNameChangeUnsubscribedMessage_Publish()
        {
            var message = new ChannelDisconnectedMessage
            {
                ConnectionId = Fixture.String()
            };

            _dispatcher.Handle(message);

            _bus.Received(1).Publish(Arg.Do<GlobalNameChangeUnsubscribedMessage>(publishedMessage => { Assert.Equal(message.ConnectionId, publishedMessage.ConnectionId); }));
        }

        [Fact]
        public void PolicingAffectedCasesSubscribedMessage_Publish()
        {
            var requestId = 1;
            var message = new ChannelConnectedMessage
            {
                ConnectionId = Fixture.String(),
                Bindings = new[] {"policing.affected.cases." + requestId, "others"}
            };

            _dispatcher.Handle(message);

            _bus.Received(1).Publish(Arg.Do<PolicingAffectedCasesSubscribedMessage>(publishedMessage =>
            {
                Assert.Equal(message.ConnectionId, publishedMessage.ConnectionId);
                Assert.Equal(requestId, publishedMessage.RequestId);
            }));
        }

        [Fact]
        public void PolicingAffectedCasesUnsubscribedMessage_Publish()
        {
            var message = new ChannelDisconnectedMessage
            {
                ConnectionId = Fixture.String()
            };

            _dispatcher.Handle(message);

            _bus.Received(1).Publish(Arg.Do<PolicingAffectedCasesUnsubscribedMessage>(publishedMessage => { Assert.Equal(message.ConnectionId, publishedMessage.ConnectionId); }));
        }

        [Fact]
        public void PolicingChangeSubscribedMessage_Publish()
        {
            var message = new ChannelConnectedMessage
            {
                ConnectionId = Fixture.String(),
                Bindings = new[] {"policing.change." + CaseId, "others"}
            };

            _dispatcher.Handle(message);

            _bus.Received(1).Publish(Arg.Do<PolicingChangeSubscribedMessage>(publishedMessage =>
            {
                Assert.Equal(message.ConnectionId, publishedMessage.ConnectionId);
                Assert.Equal(CaseId, publishedMessage.CaseId);
            }));
        }

        [Fact]
        public void PolicingChangeUnsubscribedMessage_Publish()
        {
            var message = new ChannelDisconnectedMessage
            {
                ConnectionId = Fixture.String()
            };

            _dispatcher.Handle(message);

            _bus.Received(1).Publish(Arg.Do<PolicingChangeUnsubscribedMessage>(publishedMessage => { Assert.Equal(message.ConnectionId, publishedMessage.ConnectionId); }));
        }
        
        [Fact]
        public void BackgroundNotificationSubscribedMessage_Publish()
        {
            var message = new ChannelConnectedMessage
            {
                ConnectionId = Fixture.String(),
                Bindings = new[] {"background.notification." + IdentityId, "others"}
            };

            _dispatcher.Handle(message);

            _bus.Received(1).Publish(Arg.Do<BackgroundNotificationSubscribedMessage>(publishedMessage =>
            {
                Assert.Equal(message.ConnectionId, publishedMessage.ConnectionId);
                Assert.Equal(IdentityId, publishedMessage.IdentityId);
            }));
        }

        [Fact]
        public void BackgroundNotificationUnsubscribedMessage_Publish()
        {
            var message = new ChannelDisconnectedMessage
            {
                ConnectionId = Fixture.String()
            };

            _dispatcher.Handle(message);

            _bus.Received(1).Publish(Arg.Do<BackgroundNotificationUnsubscribedMessage>(publishedMessage => { Assert.Equal(message.ConnectionId, publishedMessage.ConnectionId); }));
        }

    }
}