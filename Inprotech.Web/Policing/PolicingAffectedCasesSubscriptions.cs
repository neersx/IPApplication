using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts.Messages.Channel;
using Inprotech.Infrastructure.Messaging;

namespace Inprotech.Web.Policing
{
    public interface IPolicingAffectedCasesSubscriptions
    {
        IEnumerable<int> NewRequestids { get; }

        void SetInprogress(int[] inProccessRequestIds);
    }

    public class PolicingAffectedCasesSubscriptions : IHandle<PolicingAffectedCasesSubscribedMessage>, IHandle<PolicingAffectedCasesUnsubscribedMessage>, IPolicingAffectedCasesSubscriptions
    {
        readonly ConcurrentDictionary<string, int> _internalMap = new ConcurrentDictionary<string, int>();

        IEnumerable<int> RequestIds => _internalMap.Values.Distinct();
        List<int> InProcessRequestIds { get; } = new List<int>();

        public IEnumerable<int> NewRequestids
        {
            get { return RequestIds.Where(_ => !InProcessRequestIds.Contains(_)); }
        }

        public void SetInprogress(int[] inProccessRequestIds)
        {
            InProcessRequestIds.AddRange(inProccessRequestIds);
        }

        public void Handle(PolicingAffectedCasesSubscribedMessage message)
        {
            _internalMap.TryAdd(message.ConnectionId, message.RequestId);
        }

        public void Handle(PolicingAffectedCasesUnsubscribedMessage message)
        {
            int requestId;
            _internalMap.TryRemove(message.ConnectionId, out requestId);
            InProcessRequestIds.RemoveAll(_=>_==requestId);
        }
    }
}