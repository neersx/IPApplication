using System.Collections.Generic;
using System.Data.Entity.Infrastructure;
using System.Linq;
using System.Linq.Expressions;

namespace Inprotech.Tests.Fakes
{
    internal class InMemoryDbAsyncEnumerable<T> : EnumerableQuery<T>, IDbAsyncEnumerable<T>, IQueryable<T>
    {
        public InMemoryDbAsyncEnumerable(IEnumerable<T> enumerable)
            : base(enumerable)
        {
        }

        public InMemoryDbAsyncEnumerable(Expression expression)
            : base(expression)
        {
        }

        public IDbAsyncEnumerator<T> GetAsyncEnumerator()
        {
            return new InMemoryDbAsyncEnumerator<T>(this.AsEnumerable().GetEnumerator());
        }

        IDbAsyncEnumerator IDbAsyncEnumerable.GetAsyncEnumerator()
        {
            return GetAsyncEnumerator();
        }

        IQueryProvider IQueryable.Provider => new InMemoryDbAsyncQueryProvider<T>(this);
    }

    public static class DbAsyncEnumerableExt
    {
        public static IQueryable AsDbAsyncEnumerble<T>(this IEnumerable<T> enumerable)
        {
            return new InMemoryDbAsyncEnumerable<T>(enumerable);
        }
    }

    public static class AsyncQueryableExtensions
    {
        public static IQueryable<TElement> AsAsyncQueryable<TElement>(this IEnumerable<TElement> source)
        {
            return new InMemoryDbAsyncEnumerable<TElement>(source);
        }

        public static IDbAsyncEnumerable<TElement> AsDbAsyncEnumerable<TElement>(this IEnumerable<TElement> source)
        {
            return new InMemoryDbAsyncEnumerable<TElement>(source);
        }

        public static EnumerableQuery<TElement> AsAsyncEnumerableQuery<TElement>(this IEnumerable<TElement> source)
        {
            return new InMemoryDbAsyncEnumerable<TElement>(source);
        }

        public static IQueryable<TElement> AsAsyncQueryable<TElement>(this Expression expression)
        {
            return new InMemoryDbAsyncEnumerable<TElement>(expression);
        }

        public static IDbAsyncEnumerable<TElement> AsDbAsyncEnumerable<TElement>(this Expression expression)
        {
            return new InMemoryDbAsyncEnumerable<TElement>(expression);
        }

        public static EnumerableQuery<TElement> AsAsyncEnumerableQuery<TElement>(this Expression expression)
        {
            return new InMemoryDbAsyncEnumerable<TElement>(expression);
        }
    }
}