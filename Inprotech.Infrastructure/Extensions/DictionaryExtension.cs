using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Infrastructure.Extensions
{
    public static class DictionaryExtension
    {
        public static TValue Get<TKey, TValue>(this Dictionary<TKey, TValue> dictionary, TKey key)
        {
            if (key == null) return default(TValue);

            return dictionary.TryGetValue(key, out TValue v) ? v : default(TValue);
        }
        
        public static void AddOrReplace<TKey, TValue>(this Dictionary<TKey, TValue> dictionary, TKey key, TValue value)
        {
            if (dictionary.ContainsKey(key))
            {
                dictionary[key] = value;
            }
            else
            {
                dictionary.Add(key, value);
            }
        }
    }
}