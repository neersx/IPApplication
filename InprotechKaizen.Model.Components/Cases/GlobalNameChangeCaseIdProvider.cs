using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts.Messages.Channel;
using Inprotech.Infrastructure.Messaging;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IGlobalNameChangeCaseIdProvider
    {
        IEnumerable<int> CaseIds { get; }
    }

    public class GlobalNameChangeCaseIdProvider : IHandle<GlobalNameChangeSubscribedMessage>, IHandle<GlobalNameChangeUnsubscribedMessage>, IGlobalNameChangeCaseIdProvider
    {
        readonly ConcurrentDictionary<string, int> _internalMap = new ConcurrentDictionary<string, int>();

        public void Handle(GlobalNameChangeSubscribedMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            _internalMap.TryAdd(message.ConnectionId, message.CaseId);
        }

        public void Handle(GlobalNameChangeUnsubscribedMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));

            int caseId;
            _internalMap.TryRemove(message.ConnectionId, out caseId);
        }

        public IEnumerable<int> CaseIds
        {
            get
            {
                return _internalMap.Values.Distinct();
            }
        }
    }
}