using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Infrastructure.Extensions
{
    public static class LinqExtensions
    {
        public static Splitted<T> Split<T>(this IEnumerable<T> source, Predicate<T> predicate)
        {
            if (source == null) throw new ArgumentNullException("source");
            if (predicate == null) throw new ArgumentNullException("predicate");

            return new Splitted<T>(source, predicate);
        }

        public static T Coalesce<T>(params T[] collection)
        {
            return collection.FirstOrDefault(s => s != null);
        }

    }
}