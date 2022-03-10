using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using System.Threading.Tasks;
using System.Transactions;
using FakeDb;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using IsolationLevel = System.Transactions.IsolationLevel;

namespace Inprotech.Tests.Fakes
{
    public class InMemoryDbContext : IRepository, IDbContext
    {
        Queue<IEnumerable<object>> _sqlQueryReturns;
        public ITransactionScope TransactionScope { get; private set; }

        public Db Db { get; } = new Db().WithForeignKeyInitializer();

        public Queue<IEnumerable<object>> SqlQueryReturnQueue => _sqlQueryReturns ?? (_sqlQueryReturns = new Queue<IEnumerable<object>>());

        public ITransactionScope BeginTransaction(IsolationLevel isolationLevel = IsolationLevel.ReadCommitted,
                                                  TransactionScopeAsyncFlowOption asyncFlowOption = TransactionScopeAsyncFlowOption.Suppress)
        {
            return TransactionScope = Substitute.For<ITransactionScope>();
        }
        
        public ITransactionScope BeginTransaction(IsolationLevel isolationLevel = IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption asyncFlowOption = TransactionScopeAsyncFlowOption.Suppress, int? commandTimeout = null)
        {
            return TransactionScope = Substitute.For<ITransactionScope>();
        }

        public SqlCommand CreateSqlCommand(string text, IDictionary<string, object> parameters = null,
                                           CommandType type = CommandType.Text)
        {
            throw new NotImplementedException();
        }

        public IEnumerable<T> SqlQuery<T>(string command, params object[] arguments)
        {
            var next = SqlQueryReturnQueue.Dequeue();
            if (next is IEnumerable<T>)
            {
                return next.Select(_ => (T) _);
            }

            return null;
        }

        public IEnumerable<T> AddRange<T>(IEnumerable<T> entities) where T : class
        {
            var addRange = entities as T[] ?? entities.ToArray();
            foreach (var e in addRange)
                Db.Set<T>().Add(e);

            return addRange;
        }

        public IEnumerable<T> RemoveRange<T>(IEnumerable<T> entities) where T : class
        {
            var removeRange = entities as T[] ?? entities.ToArray();
            foreach (var e in removeRange)
                Db.Set<T>().Remove(e);

            return removeRange;
        }

        public T Detach<T>(T entity) where T : class
        {
            return entity;
        }

        public Action<string> Log
        {
            set { }
        }

        public int Delete<TEntity>(Expression<Func<TEntity, bool>> expression) where TEntity : class
        {
            return Delete(Set<TEntity>().Where(expression));
        }

        public SqlCommand CreateStoredProcedureCommand(string storedProcedureName, IDictionary<string, object> parameters = null)
        {
            throw new NotImplementedException();
        }

        public IDbSet<T> Set<T>() where T : class
        {
            return new InMemorySet<T>(Db.Set<T>());
        }

        public virtual void SaveChanges()
        {
        }

        public virtual Task SaveChangesAsync()
        {
            return Task.FromResult(0);
        }

        public int Delete<TEntity>(IQueryable<TEntity> source) where TEntity : class
        {
            var items = source.ToArray();
            foreach (var item in items)
                Db.Set<TEntity>().Remove(item);

            return items.Length;
        }

        public int Update<TEntity>(IQueryable<TEntity> source, Expression<Func<TEntity, TEntity>> updateExpression) where TEntity : class
        {
            var bindings = ((MemberInitExpression) updateExpression.Body).Bindings;
            var propertyInfos = new List<PropertyInfo>();
            var items = source.ToArray();

            foreach (var binding in bindings)
            {
                var member = (PropertyInfo) ((MemberAssignment) binding).Member;
                propertyInfos.Add(member);
            }

            var method = updateExpression.Compile();

            foreach (var item in items)
            {
                var newItem = method.Invoke(item);
                foreach (var propertyInfo in propertyInfos)
                {
                    var value = propertyInfo.GetMethod.Invoke(newItem, null);
                    propertyInfo.SetMethod.Invoke(item, new[] {value});
                }
            }

            return items.Length;
        }

        public Task<int> DeleteAsync<TEntity>(IQueryable<TEntity> source) where TEntity : class
        {
            var ret = Delete(source);
            return Task.FromResult(ret);
        }

        public Task<int> DeleteAsync<TEntity>(Expression<Func<TEntity, bool>> expression) where TEntity : class
        {
            var ret = Delete(expression);
            return Task.FromResult(ret);
        }

        public Task<int> UpdateAsync<TEntity>(IQueryable<TEntity> source, Expression<Func<TEntity, TEntity>> updateExpression) where TEntity : class
        {
            var ret = Update(source, updateExpression);
            return Task.FromResult(ret);
        }

        public T Reload<T>(T instance) where T : class
        {
            return instance;
        }

        public void SetCommandTimeOut(int? seconds)
        {
        }
        
        public virtual void Dispose()
        {
        }
    }

    public static class TestHelpers
    {
        public static T In<T>(this T value, InMemoryDbContext db) where T : class
        {
            db.Set<T>().Add(value);
            return value;
        }
    }
}