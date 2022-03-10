using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts.Messages.Channel;
using Inprotech.Infrastructure.Messaging;

namespace InprotechKaizen.Model.Components.System.BackgroundProcess
{
    public interface IBackgroundNotificationUsernameProvider
    {
        IEnumerable<int> IdentityId { get; }
        Dictionary<int, List<int>> PublishedData { get; }

    }

    public class BackgroundNotificationUsernameProvider : IHandle<BackgroundNotificationSubscribedMessage>, IHandle<BackgroundNotificationUnsubscribedMessage>, IBackgroundNotificationUsernameProvider
    {
        readonly ConcurrentDictionary<string, int> _internalMap = new ConcurrentDictionary<string, int>();
        readonly Dictionary<int, List<int>> _publishedData = new Dictionary<int, List<int>>();

        public void Handle(BackgroundNotificationSubscribedMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));
            _internalMap.TryAdd(message.ConnectionId, message.IdentityId);
            if (_publishedData.ContainsKey(message.IdentityId))
            {
                _publishedData[message.IdentityId] = new List<int>();
            }
            else
            {
                _publishedData.Add(message.IdentityId, new List<int>());
            }
        }

        public void Handle(BackgroundNotificationUnsubscribedMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            _internalMap.TryRemove(message.ConnectionId, out _);
        }

        public IEnumerable<int> IdentityId => _internalMap.Values.Distinct();

        public Dictionary<int, List<int>> PublishedData => _publishedData;
    }
}
