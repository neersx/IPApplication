using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts.Messages.Channel;
using Inprotech.Infrastructure.Messaging;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IPolicingChangeCaseIdProvider
    {
        IEnumerable<int> CaseIds { get; }
        Dictionary<int, string> PublishedData { get; }
    }

    public class PolicingChangeCaseIdProvider : IHandle<PolicingChangeSubscribedMessage>, IHandle<PolicingChangeUnsubscribedMessage>, IPolicingChangeCaseIdProvider
    {
        readonly ConcurrentDictionary<string, int> _internalMap = new ConcurrentDictionary<string, int>();
        readonly Dictionary<int, string> _publishedData = new Dictionary<int, string>();

        public void Handle(PolicingChangeSubscribedMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            _internalMap.TryAdd(message.ConnectionId, message.CaseId);
            if (_publishedData.ContainsKey(message.CaseId))
            {
                _publishedData[message.CaseId] = null;
            }
            else
            {
                _publishedData.Add(message.CaseId, null);
            }
        }

        public void Handle(PolicingChangeUnsubscribedMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            _internalMap.TryRemove(message.ConnectionId, out _);
        }

        public IEnumerable<int> CaseIds => _internalMap.Values.Distinct();

        public Dictionary<int, string> PublishedData => _publishedData;
    }
}
