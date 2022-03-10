using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Caching
{
    public interface ILifetimeScopeCache
    {
        TValue GetOrAdd<TOwner, TKey, TValue>(TOwner owner, TKey key, Func<TKey, TValue> valueFactory);
        /// <summary>
        /// WARNING
        /// <para>If the valueFactory failed, the failed task will be held in cache so that would not be very good.</para>
        /// <para>Consumer of this API should use with care.</para>
        /// </summary>
        Task<TValue> GetOrAddAsync<TOwner, TKey, TValue>(TOwner owner, TKey key, Func<TKey, Task<TValue>> valueFactory);

        bool Update<TOwner, TKey, TValue>(TOwner owner, TKey key, TValue value, TValue comparisonValue);
    }

    public class LifetimeScopeCache : ILifetimeScopeCache
    {
        readonly ConcurrentDictionary<object, object> _dictionariesPerOwner;

        public LifetimeScopeCache()
        {
            _dictionariesPerOwner = new ConcurrentDictionary<object, object>();
        }

        public TValue GetOrAdd<TOwner, TKey, TValue>(TOwner owner, TKey key, Func<TKey, TValue> valueFactory)
        {
            var perOwner = (ConcurrentDictionary<TKey, TValue>) _dictionariesPerOwner.GetOrAdd(
                                                                                               new
                                                                                               {
                                                                                                   to = typeof(TOwner),
                                                                                                   tv = typeof(TValue)
                                                                                               },
                                                                                               k => new ConcurrentDictionary<TKey, TValue>());

            return perOwner.GetOrAdd(key, valueFactory);
        }

        /// <summary>
        /// WARNING
        /// <para>If the valueFactory failed, the failed task will be held in cache so that would not be very good.</para>
        /// <para>Consumer of this API should use with care.</para>
        /// </summary>
        public async Task<TValue> GetOrAddAsync<TOwner, TKey, TValue>(TOwner owner, TKey key, Func<TKey, Task<TValue>> valueFactory)
        {
            var perOwner = (ConcurrentDictionary<TKey, TValue>)_dictionariesPerOwner.GetOrAdd(
                                                                                              new
                                                                                              {
                                                                                                  to = typeof(TOwner),
                                                                                                  tv = typeof(TValue)
                                                                                              },
                                                                                              k => new ConcurrentDictionary<TKey, TValue>());
            
            return perOwner.GetOrAdd(key, await valueFactory(key));
        }

        public bool Update<TOwner, TKey, TValue>(TOwner owner, TKey key, TValue value, TValue comparisonValue)
        {
            var perOwner = (ConcurrentDictionary<TKey, TValue>) _dictionariesPerOwner.GetOrAdd(
                                                                                               new
                                                                                               {
                                                                                                   to = typeof(TOwner),
                                                                                                   tv = typeof(TValue)
                                                                                               },
                                                                                               k => new ConcurrentDictionary<TKey, TValue>());

            return perOwner.TryUpdate(key, value, comparisonValue);
        }
    }
}