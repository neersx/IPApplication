using System.Collections.Generic;

namespace Inprotech.Infrastructure
{
    public interface ITemporaryStorage
    {
        object Get(string key);
        void Save(string key, object value);
        void Delete(string key);
    }

    class TemporaryStorage : ITemporaryStorage
    {
        readonly IDictionary<string, object> _storage = new Dictionary<string, object>();

        public object Get(string key)
        {
            lock (_storage)
            {
                object value;
                _storage.TryGetValue(key, out value);

                return value;
            }
        }

        public void Save(string key, object value)
        {
            lock (_storage)
            {
                _storage[key] = value;
            }
        }

        public void Delete(string key)
        {
            lock (_storage)
            {
                _storage.Remove(key);
            }
        }
    }
}