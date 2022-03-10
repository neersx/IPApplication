using System.Linq;
using Inprotech.Contracts.Messages.Channel;
using InprotechKaizen.Model.Components.System.BackgroundProcess;
using Xunit;

namespace Inprotech.Tests.Web.Messaging
{
    public class BackgroundNotificationUsernameProviderFacts
    {
        readonly BackgroundNotificationUsernameProvider _provider = new BackgroundNotificationUsernameProvider();

        [Fact]
        public void AddsUsernameOnSubscription()
        {
            _provider.Handle(new BackgroundNotificationSubscribedMessage
            {
                ConnectionId = "1",
                IdentityId = 45
            });

            _provider.Handle(new BackgroundNotificationSubscribedMessage
            {
                ConnectionId = "2",
                IdentityId= 46
            });

            Assert.Equal(new[] {45, 46}, _provider.IdentityId.OrderBy(_ => _).ToArray());
        }

        [Fact]
        public void IfKeyAlreadyExists()
        {
            _provider.Handle(new BackgroundNotificationSubscribedMessage
            {
                ConnectionId = "1",
                IdentityId = 45
            });

            _provider.Handle(new BackgroundNotificationSubscribedMessage
            {
                ConnectionId = "1",
                IdentityId = 45
            });

            Assert.Equal(new[] {45}, _provider.IdentityId);
        }

        [Fact]
        public void IfKeyDoesNotExistShouldNotThrowException()
        {
            _provider.Handle(new BackgroundNotificationUnsubscribedMessage
            {
                ConnectionId = "1"
            });
        }

        [Fact]
        public void RemovesUsernameOnUnSubscription()
        {
            _provider.Handle(new BackgroundNotificationSubscribedMessage()
            {
                ConnectionId = "1",
                IdentityId = 45
            });

            _provider.Handle(new BackgroundNotificationUnsubscribedMessage()
            {
                ConnectionId = "1"
            });

            Assert.Empty(_provider.IdentityId);
        }
        
        [Fact]
        public void ReturnsUniqueUsernames()
        {
            _provider.Handle(new BackgroundNotificationSubscribedMessage
            {
                ConnectionId = "1",
                IdentityId = 45
            });

            _provider.Handle(new BackgroundNotificationSubscribedMessage
            {
                ConnectionId = "2",
                IdentityId = 45
            });

            Assert.Equal(new[] { 45}, _provider.IdentityId);
        }

    }
}
