using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Data.Entity.Core.EntityClient;
using System.Data.Entity.Infrastructure;
using System.Data.SqlClient;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Linq.Expressions;
using System.Threading.Tasks;
using Z.EntityFramework.Plus;

namespace Inprotech.Integration.Persistence
{
    public class IntegrationDbContext : DbContext, IRepository
    {
        readonly IEnumerable<IModelBuilder> _modelBuilders;

        public IntegrationDbContext() : base("name=InprotechIntegration")
        {
            _modelBuilders = IntegrationDbContextHelpers.ResolveModelBuilders();
        }

        public new IDbSet<T> Set<T>() where T : class
        {
            return base.Set<T>();
        }

        public new void SaveChanges()
        {
            base.SaveChanges();
        }

        public new async Task SaveChangesAsync()
        {
            await base.SaveChangesAsync();
        }

        [SuppressMessage("Microsoft.Security", "CA2100:Review SQL queries for security vulnerabilities")]
        public SqlCommand CreateStoredProcedureCommand(string storedProcedureName, IDictionary<string, object> parameters = null)
        {
            EnsureConnection();

            return new SqlCommand(storedProcedureName, (SqlConnection) Database.Connection)
                   {
                       CommandType = CommandType.StoredProcedure
                   };
        }

        public int Delete<TEntity>(IQueryable<TEntity> source) where TEntity : class
        {
            if (source == null) throw new ArgumentNullException(nameof(source));

            var context = ((IObjectContextAdapter) this).ObjectContext;
            foreach (var s in source)
            {
                var stateEntry = context.ObjectStateManager.GetObjectStateEntry(s);
                stateEntry.Delete();
                stateEntry.AcceptChanges();
            }

            return source.Delete();
        }

        public async Task<int> DeleteAsync<TEntity>(IQueryable<TEntity> source) where TEntity : class
        {
            if (source == null) throw new ArgumentNullException(nameof(source));

            var context = ((IObjectContextAdapter) this).ObjectContext;
            foreach (var s in source)
            {
                var stateEntry = context.ObjectStateManager.GetObjectStateEntry(s);
                stateEntry.Delete();
                stateEntry.AcceptChanges();
            }

            return await source.DeleteAsync();
        }

        public async Task<int> DeleteAsync<TEntity>(Expression<Func<TEntity, bool>> expression) where TEntity : class
        {
            return await DeleteAsync(Set<TEntity>().Where(expression));
        }

        public int Update<TEntity>(IQueryable<TEntity> source, Expression<Func<TEntity, TEntity>> updateExpression) where TEntity : class
        {
            return source.Update(updateExpression);
        }

        public async Task<int> UpdateAsync<TEntity>(IQueryable<TEntity> source, Expression<Func<TEntity, TEntity>> updateExpression) where TEntity : class
        {
            return await source.UpdateAsync(updateExpression);
        }

        public int Delete<TEntity>(Expression<Func<TEntity, bool>> expression) where TEntity : class
        {
            return Delete(Set<TEntity>().Where(expression));
        }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            foreach (var b in _modelBuilders)
                b.Build(modelBuilder);
        }

        SqlConnection EnsureConnection()
        {
            var connection = ((IObjectContextAdapter) this).ObjectContext.Connection;

            if (connection.State != ConnectionState.Open)
            {
                if (connection.State == ConnectionState.Broken)
                {
                    connection.Close();
                }

                connection.Open();
            }

            return (SqlConnection) ((EntityConnection) connection).StoreConnection;
        }

        public T Reload<T>(T instance) where T : class
        {
            var entry = Entry(instance);
            entry.Reload();

            return entry.Entity;
        }

        public IEnumerable<T> AddRange<T>(IEnumerable<T> entities) where T : class
        {
            return base.Set<T>().AddRange(entities);
        }
    }
}