using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Infrastructure.Extensions
{
    public static class EnumerableExtensions
    {
        public static IEnumerable<T> AddAll<T>(this ICollection<T> target, params IEnumerable<T>[] sources)
        {
            if(target == null) throw new ArgumentNullException(nameof(target));
            if(sources == null) throw new ArgumentNullException(nameof(sources));

            foreach(var source in sources)
                foreach(var item in source)
                    target.Add(item);

            return target;
        }

        public static HashSet<T> ToHashSet<T>(this IEnumerable<T> source)
        {
            return new HashSet<T>(source);
        }

        public static IEnumerable<T> DistinctBy<T, TKey>(this IEnumerable<T> items,
            Func<T, TKey> property)
        {
            return items.GroupBy(property).Select(x => x.First());
        }

        public static T[] RemoveRange<T>(this T[] source, int index, int count)
        {
            if (source == null) throw new ArgumentNullException("source");

            var s = source.ToList();

            s.RemoveRange(index, count);

            return s.ToArray();
        }
    }
}