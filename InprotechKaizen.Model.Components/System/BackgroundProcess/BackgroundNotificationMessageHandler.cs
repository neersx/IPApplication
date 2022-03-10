using System.Linq;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Notifications;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.System.Messages;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.System.BackgroundProcess
{
    public interface IHandleBackgroundNotificationMessage
    {
        void For(int identityId);
    }

    public class HandleBackgroundNotificationMessage : IHandleBackgroundNotificationMessage
    {
        readonly IBackgroundProcessMessageClient _backgroundProcessMessage;
        readonly IBus _bus;

        public HandleBackgroundNotificationMessage(IBackgroundProcessMessageClient backgroundProcessMessageClient, IBus bus)
        {
            _backgroundProcessMessage = backgroundProcessMessageClient;
            _bus = bus;
        }

        public void For(int identityId)
        {
            var timerStoppedMessages = _backgroundProcessMessage.Get(new[]{ identityId });
            foreach (var backgroundProcessMessage in timerStoppedMessages.Where(_ => _.ProcessSubType == BackgroundProcessSubType.TimerStopped))
            {
                var serializeSettings = new JsonSerializerSettings
                {
                    DateParseHandling = DateParseHandling.DateTime,
                    DateTimeZoneHandling = DateTimeZoneHandling.RoundtripKind
                };
                var timerStoppedMessage = new BroadcastMessageToClient
                {
                    Topic = $"time.recording.timerStarted{backgroundProcessMessage.IdentityId}",
                    Data = new
                    {
                        BasicDetails = JsonConvert.DeserializeObject<StoppedTimerInfo>(backgroundProcessMessage.StatusInfo, serializeSettings),
                        HasActiveTimer = false,
                        HasAutoStoppedTimer = true
                    }
                };
                _bus.Publish(timerStoppedMessage);
            }
        }
    }
}
