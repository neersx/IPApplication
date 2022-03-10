using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Messaging
{
    public interface IClientSubscriptions
    {
        void Add(string id, IEnumerable<string> bindings);

        void Remove(string id);
        IEnumerable<string> Find(string key, Func<string, string, bool> match);
    }

    public class ClientSubscriptions : IClientSubscriptions
    {
        readonly ConcurrentDictionary<string, List<string>> _internalMap = new ConcurrentDictionary<string, List<string>>();

        public void Add(string id, IEnumerable<string> bindings)
        {
            if (!_internalMap.ContainsKey(id))
                _internalMap[id] = new List<string>();

            var sub = _internalMap[id];
            sub.AddRange(bindings.Except(sub));
        }

        public void Remove(string id)
        {
            List<string> bindings;

            _internalMap.TryRemove(id, out bindings);
        }

        public IEnumerable<string> Find(string key, Func<string, string, bool> match)
        {
            var result = new List<string>();

            result.AddRange(
                from pair in _internalMap
                where pair.Value.Any(a => match(a, key))
                select pair.Key);

            return result;
        }
    }
}