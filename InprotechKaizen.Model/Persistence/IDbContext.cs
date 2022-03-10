using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Linq.Expressions;
using System.Threading.Tasks;
using System.Transactions;
using IsolationLevel = System.Transactions.IsolationLevel;

namespace InprotechKaizen.Model.Persistence
{
    public interface IDbContext
    {
        Action<string> Log { set; }
        IDbSet<T> Set<T>() where T : class;
        void SaveChanges();

        Task SaveChangesAsync();

        IEnumerable<T> AddRange<T>(IEnumerable<T> entities) where T : class;

        IEnumerable<T> RemoveRange<T>(IEnumerable<T> entities) where T : class;

        ITransactionScope BeginTransaction(IsolationLevel isolationLevel = IsolationLevel.ReadCommitted,
                                           TransactionScopeAsyncFlowOption asyncFlowOption = TransactionScopeAsyncFlowOption.Suppress, int? commandTimeout = null);

        SqlCommand CreateStoredProcedureCommand(string storedProcedureName, IDictionary<string, object> parameters = null);

        SqlCommand CreateSqlCommand(string text, IDictionary<string, object> parameters = null,
                                    CommandType type = CommandType.Text);

        IEnumerable<T> SqlQuery<T>(string command, params object[] arguments);

        T Reload<T>(T instance) where T : class;

        T Detach<T>(T entity) where T : class;

        //Method for bulk delete
        int Delete<TEntity>(IQueryable<TEntity> source) where TEntity : class;

        int Delete<TEntity>(Expression<Func<TEntity, bool>> expression) where TEntity : class;

        //Method for  bulk update
        int Update<TEntity>(IQueryable<TEntity> source, Expression<Func<TEntity, TEntity>> updateExpression) where TEntity : class;

        Task<int> DeleteAsync<TEntity>(IQueryable<TEntity> source) where TEntity : class;

        Task<int> DeleteAsync<TEntity>(Expression<Func<TEntity, bool>> expression) where TEntity : class;

        Task<int> UpdateAsync<TEntity>(IQueryable<TEntity> source, Expression<Func<TEntity, TEntity>> updateExpression) where TEntity : class;

        void SetCommandTimeOut(int? seconds);
    }
}