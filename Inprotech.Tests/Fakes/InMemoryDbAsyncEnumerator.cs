using System.Collections.Generic;
using System.Data.Entity.Infrastructure;
using System.Threading;
using System.Threading.Tasks;

namespace Inprotech.Tests.Fakes
{
    internal class InMemoryDbAsyncEnumerator<T> : IDbAsyncEnumerator<T>
    {
        readonly IEnumerator<T> _inner;

        public InMemoryDbAsyncEnumerator(IEnumerator<T> inner)
        {
            _inner = inner;
        }

        public void Dispose()
        {
            _inner.Dispose();
        }

        public Task<bool> MoveNextAsync(CancellationToken cancellationToken)
        {
            return Task.FromResult(_inner.MoveNext());
        }

        public T Current => _inner.Current;

        object IDbAsyncEnumerator.Current => Current;
    }
}