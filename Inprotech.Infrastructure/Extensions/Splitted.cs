using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;

namespace Inprotech.Infrastructure.Extensions
{
    public class Splitted<T>
    {
        readonly List<T> _excluded;
        readonly List<T> _included;

        public Splitted(IEnumerable<T> source, Predicate<T> predicate)
        {
            if (source == null) throw new ArgumentNullException("source");
            if (predicate == null) throw new ArgumentNullException("predicate");

            _included = new List<T>();
            _excluded = new List<T>();

            foreach (var item in source)
            {
                if (predicate(item))
                {
                    _included.Add(item);
                }
                else
                {
                    _excluded.Add(item);
                }
            }
        }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public T[] Included => _included.ToArray();

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public T[] Excluded => _excluded.ToArray();
    }
}