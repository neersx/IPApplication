using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Transactions;

namespace Inprotech.Integration.Persistence
{
    public static class Extensions
    {
        public static IQueryable<TEntity> WithoutDeleted<TEntity>(this IDbSet<TEntity> itms)
            where TEntity : class, ISoftDeleteable
        {
            return itms.Where(i => !i.IsDeleted);
        }

        public static IEnumerable<TEntity> WithoutDeleted<TEntity>(this IEnumerable<TEntity> itms)
            where TEntity : class, ISoftDeleteable
        {
            return itms.Where(i => !i.IsDeleted);
        }

        public static IQueryable<TEntity> NoDeleteSet<TEntity>(this IRepository repository)
            where TEntity : class, ISoftDeleteable
        {
            return repository.Set<TEntity>()
                             .WithoutDeleted();
        }
        public static TransactionScope BeginTransaction(this IRepository repository, IsolationLevel isolationLevel = IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption asyncFlowOption = TransactionScopeAsyncFlowOption.Suppress, TransactionScopeOption scopeOption = TransactionScopeOption.Required)
        {
            return new TransactionScope(
                scopeOption,
                new TransactionOptions { IsolationLevel = isolationLevel },
                asyncFlowOption);
        }

        public static IRepository WithUntrackedContext(this IRepository repository)
        {
            var context = repository as IntegrationDbContext;
            if (context != null)
                context.Configuration.AutoDetectChangesEnabled = false;
            return repository;
        }
    }
}