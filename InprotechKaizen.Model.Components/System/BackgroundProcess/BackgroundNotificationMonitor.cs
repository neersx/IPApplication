using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Notifications;
using InprotechKaizen.Model.Components.System.Messages;

namespace InprotechKaizen.Model.Components.System.BackgroundProcess
{
    
    public interface IBackgroundNotificationMonitor : IMonitorClockRunnable
    {
    }

    public class BackgroundNotificationMonitor : IBackgroundNotificationMonitor
    {
        readonly IBus _bus;
        readonly IBackgroundNotificationUsernameProvider _usernameProvider;
        readonly IBackgroundProcessMessageClient _backgroundProcessMessage;
        readonly IHandleBackgroundNotificationMessage _handleBackgroundNotificationMessage;

        public BackgroundNotificationMonitor(IBus bus, IBackgroundNotificationUsernameProvider usernameProvider, IBackgroundProcessMessageClient backgroundProcessMessage, IHandleBackgroundNotificationMessage handleBackgroundNotificationMessage)
        {
            _bus = bus;
            _usernameProvider = usernameProvider;
            _backgroundProcessMessage = backgroundProcessMessage;
            _handleBackgroundNotificationMessage = handleBackgroundNotificationMessage;
        }

        public void Run()
        {
            var identityIds = _usernameProvider.IdentityId.ToArray();
            if (!identityIds.Any())
                return;

            var backgroundProcessMessages = _backgroundProcessMessage.Get(identityIds, true);

            foreach (var identity in identityIds)
            {
                var processIds = backgroundProcessMessages.Where(_ => _.IdentityId == identity).Select(_ => _.ProcessId).ToList();
                if(PreventPublishingSameData(identity, processIds)) continue;

                var message = new BroadcastMessageToClient
                {
                    Topic = "background.notification." + identity,
                    Data = processIds
                };
                _bus.Publish(message);

                _handleBackgroundNotificationMessage.For(identity);
            }
        }

        bool PreventPublishingSameData(int identity, List<int> processIds)
        {
            var dataToCompare = _usernameProvider.PublishedData[identity];
            if ( dataToCompare.Count == processIds.Count && dataToCompare.All(processIds.Contains)) return true;
            _usernameProvider.PublishedData[identity] = processIds;
            return false;
        }
    }
}
