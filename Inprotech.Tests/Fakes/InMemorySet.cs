using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Data.Entity;
using System.Data.Entity.Infrastructure;
using System.Linq;
using System.Linq.Expressions;
using FakeDb;

namespace Inprotech.Tests.Fakes
{
    internal class InMemorySet<T> : IDbSet<T>, IDbAsyncEnumerable<T> where T : class
    {
        readonly IInMemorySet _internalSet;

        public InMemorySet(IInMemorySet internalSet)
        {
            _internalSet = internalSet;
        }

        public IDbAsyncEnumerator<T> GetAsyncEnumerator()
        {
            return new InMemoryDbAsyncEnumerator<T>(GetEnumerator());
        }

        IDbAsyncEnumerator IDbAsyncEnumerable.GetAsyncEnumerator()
        {
            return GetAsyncEnumerator();
        }

        public T Add(T entity)
        {
            _internalSet.Add(entity);
            return entity;
        }

        public T Attach(T entity)
        {
            return entity;
        }

        public TDerivedEntity Create<TDerivedEntity>() where TDerivedEntity : class, T
        {
            throw new NotImplementedException();
        }

        public T Create()
        {
            return (T) Activator.CreateInstance(typeof(T), new object[] { });
        }

        public T Find(params object[] keyValues)
        {
            throw new NotImplementedException();
        }

        public ObservableCollection<T> Local => throw new NotImplementedException();

        public T Remove(T entity)
        {
            if (_internalSet.Remove(entity) == null)
            {
                throw new InvalidOperationException("Could not remove the item. Item does not exist.");
            }

            return entity;
        }

        public IEnumerator<T> GetEnumerator()
        {
            return _internalSet.Items.Cast<T>().GetEnumerator();
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return _internalSet.Items.GetEnumerator();
        }

        public Type ElementType => typeof(T);

        public Expression Expression => _internalSet.Items.Cast<T>().AsQueryable().Expression;

        public IQueryProvider Provider => new InMemoryDbAsyncQueryProvider<T>(_internalSet.Items.Cast<T>().AsQueryable().Provider);
    }
}