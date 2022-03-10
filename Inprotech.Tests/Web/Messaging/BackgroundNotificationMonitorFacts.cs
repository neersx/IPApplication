using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Notifications;
using InprotechKaizen.Model.Components.System.BackgroundProcess;
using InprotechKaizen.Model.Components.System.Messages;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Messaging
{
    public class BackgroundNotificationMonitorFacts : FactBase
    {
        [Fact]
        public void TestComposition()
        {
          
            var identityId = Fixture.Integer();
            var identityId2 = Fixture.Integer();
            var processId = Fixture.Integer();
            var usernameProvider = Substitute.For<IBackgroundNotificationUsernameProvider>();
            var messageClient = Substitute.For<IBackgroundProcessMessageClient>();
            var bus = Substitute.For<IBus>();
            var handleMessages = Substitute.For<IHandleBackgroundNotificationMessage>();

            usernameProvider.IdentityId.Returns(new[] {identityId, identityId2});
            var alreadyPublishedUserData = new Dictionary<int, List<int>> {{identityId, new List<int>()}, {identityId2, new List<int>()}};

            usernameProvider.PublishedData.Returns(alreadyPublishedUserData);
            var backgroundProcessMessages = new List<BackgroundProcessMessage> {new BackgroundProcessMessage {IdentityId = identityId, ProcessType = BackgroundProcessType.GlobalCaseChange, ProcessId = processId, StatusType = StatusType.Completed}};
            messageClient.Get(Arg.Is<IEnumerable<int>>(_ => _.Single() == identityId))
                         .ReturnsForAnyArgs(backgroundProcessMessages);

            var monitor = new BackgroundNotificationMonitor(bus, usernameProvider, messageClient, handleMessages);

            monitor.Run();

            bus.Received(1).Publish(Arg.Is<BroadcastMessageToClient>(m => m.Topic.Equals($"background.notification.{identityId}") && (m.Data as List<int>)[0] == processId));
            handleMessages.Received(1).For(identityId);
        }
   
    }
}
