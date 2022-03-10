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
using System.Transactions;
using CodeFirstStoreFunctions;
using Z.EntityFramework.Plus;
using IsolationLevel = System.Transactions.IsolationLevel;

namespace InprotechKaizen.Model.Persistence
{
    public partial class SqlDbContext : DbContext, IDbContext, IChangeTracker
    {
        readonly IEnumerable<IModelBuilder> _modelBuilders;

        public SqlDbContext()
            : base("name=Inprotech")
        {
            _modelBuilders = DbContextHelpers.ResolveModelBuilders();
        }

        public bool HasChanged(object instance)
        {
            var entry = Entry(instance);
            return entry.State == EntityState.Added || entry.State == EntityState.Modified;
        }

        public new IDbSet<T> Set<T>() where T : class
        {
            return base.Set<T>();
        }

        public IEnumerable<T> AddRange<T>(IEnumerable<T> entities) where T : class
        {
            return base.Set<T>().AddRange(entities);
        }

        public IEnumerable<T> RemoveRange<T>(IEnumerable<T> entities) where T : class
        {
            return base.Set<T>().RemoveRange(entities);
        }

        public T Detach<T>(T entity) where T : class
        {
            ((IObjectContextAdapter) this).ObjectContext.Detach(entity);
            return entity;
        }

        public new void SaveChanges()
        {
            base.SaveChanges();
        }

        public new async Task SaveChangesAsync()
        {
            await base.SaveChangesAsync();
        }

        public ITransactionScope BeginTransaction(IsolationLevel isolationLevel = IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption asyncFlowOption = TransactionScopeAsyncFlowOption.Suppress, int? commandTimeout = null)
        {
            EnsureConnection(commandTimeout);
            return new TransactionScopeImpl(
                                            isolationLevel,
                                            asyncFlowOption);
        }

        [SuppressMessage("Microsoft.Security", "CA2100:Review SQL queries for security vulnerabilities")]
        public SqlCommand CreateStoredProcedureCommand(string storedProcedureName, IDictionary<string, object> parameters = null)
        {
            if (storedProcedureName == null) throw new ArgumentNullException(nameof(storedProcedureName));

            EnsureConnection();

            var command = new SqlCommand(storedProcedureName, (SqlConnection) Database.Connection)
                   {
                       CommandType = CommandType.StoredProcedure
                   };

            if (parameters == null) return command;

            SqlCommandBuilder.DeriveParameters(command);

            foreach (var i in parameters)
                command.Parameters[i.Key].Value = i.Value;

            return command;
        }

        [SuppressMessage("Microsoft.Security", "CA2100:Review SQL queries for security vulnerabilities")]
        public SqlCommand CreateSqlCommand(string text, IDictionary<string, object> parameters = null, CommandType type = CommandType.Text)
        {
            if (String.IsNullOrWhiteSpace(text)) throw new ArgumentNullException(nameof(text));

            var connection = EnsureConnection();
            var command = connection.CreateCommand();

            command.CommandText = text;
            command.CommandType = type;

            if (parameters != null)
            {
                foreach (var i in parameters)
                    command.Parameters.AddWithValue(i.Key, i.Value);
            }

            return command;
        }

        public IEnumerable<T> SqlQuery<T>(string command, params object[] arguments)
        {
            return Database.SqlQuery<T>(command, arguments).ToArray();
        }

        public Action<string> Log
        {
            set { }
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

        public int Delete<TEntity>(Expression<Func<TEntity, bool>> expression) where TEntity : class
        {
            return Delete(Set<TEntity>().Where(expression));
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

        public T Reload<T>(T instance) where T : class
        {
            var entry = Entry(instance);
            entry.Reload();

            return entry.Entity;
        }
        
        [SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            modelBuilder.Conventions.Add(new FunctionsConvention<SqlDbContext>("dbo"));

            foreach (var builder in _modelBuilders)
                builder.Build(modelBuilder);
        }

        SqlConnection EnsureConnection(int? commandTimeout = null)
        {
            var ctx = ((IObjectContextAdapter) this).ObjectContext;
            var connection = ctx.Connection;

            if (commandTimeout != null)
            {
                ctx.CommandTimeout = commandTimeout;
            }

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

        public void SetCommandTimeOut(int? seconds)
        {
            var objectContext = ((IObjectContextAdapter) this).ObjectContext;
            objectContext.CommandTimeout = seconds;
        }

        class TransactionScopeImpl : ITransactionScope
        {
            readonly TransactionScope _scope;

            public TransactionScopeImpl(IsolationLevel isolationLevel, TransactionScopeAsyncFlowOption asyncFlowOption)
            {
                _scope = new TransactionScope(
                                              TransactionScopeOption.Required,
                                              new TransactionOptions {IsolationLevel = isolationLevel},
                                              asyncFlowOption);
            }

            public void Dispose()
            {
                _scope.Dispose();
            }

            public void Complete()
            {
                _scope.Complete();
            }
        }
    }
}