using System;
using System.Data.Entity.Infrastructure;
using System.Linq;
using System.Linq.Expressions;
using System.Threading;
using System.Threading.Tasks;

namespace Inprotech.Tests.Fakes
{
    internal class InMemoryDbAsyncQueryProvider<TEntity> : IDbAsyncQueryProvider
    {
        readonly IQueryProvider _inner;

        internal InMemoryDbAsyncQueryProvider(IQueryProvider inner)
        {
            _inner = inner;
        }

        public IQueryable CreateQuery(Expression expression)
        {
            switch (expression)
            {
                case MethodCallExpression m:
                {
                    var resultType = m.Method.ReturnType;
                    var tElement = resultType.GetGenericArguments()[0];
                    var queryType = typeof(InMemoryDbAsyncEnumerable<>).MakeGenericType(tElement);
                    return (IQueryable)Activator.CreateInstance(queryType, expression);
                }
            }
            return new InMemoryDbAsyncEnumerable<TEntity>(expression);
        }

        public IQueryable<TElement> CreateQuery<TElement>(Expression expression)
        {
            var queryType = typeof(InMemoryDbAsyncEnumerable<>).MakeGenericType(typeof(TElement));
            return (IQueryable<TElement>)Activator.CreateInstance(queryType, expression);
        }

        public object Execute(Expression expression)
        {
            return _inner.Execute(expression);
        }

        public TResult Execute<TResult>(Expression expression)
        {
            return _inner.Execute<TResult>(expression);
        }

        public Task<object> ExecuteAsync(Expression expression, CancellationToken cancellationToken)
        {
            return Task.FromResult(Execute(expression));
        }

        public Task<TResult> ExecuteAsync<TResult>(Expression expression, CancellationToken cancellationToken)
        {
            return Task.FromResult(Execute<TResult>(expression));
        }
    }
}