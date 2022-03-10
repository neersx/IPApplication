using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Linq.Expressions;
using System.Threading.Tasks;

namespace Inprotech.Integration.Persistence
{
    public interface IRepository
    {
        IDbSet<T> Set<T>() where T : class;

        void SaveChanges();

        Task SaveChangesAsync();

        SqlCommand CreateStoredProcedureCommand(string storedProcedureName, IDictionary<string, object> parameters = null);

        //Method for bulk delete
        int Delete<TEntity>(IQueryable<TEntity> source) where TEntity : class;

        //Method for  bulk update
        int Update<TEntity>(IQueryable<TEntity> source, Expression<Func<TEntity, TEntity>> updateExpression) where TEntity : class;

        Task<int> DeleteAsync<TEntity>(IQueryable<TEntity> source) where TEntity : class;

        Task<int> DeleteAsync<TEntity>(Expression<Func<TEntity, bool>> expression) where TEntity : class;

        Task<int> UpdateAsync<TEntity>(IQueryable<TEntity> source, Expression<Func<TEntity, TEntity>> updateExpression) where TEntity : class;

        T Reload<T>(T instance) where T : class;

        IEnumerable<T> AddRange<T>(IEnumerable<T> entities) where T : class;
    }
}