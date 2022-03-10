using System;
using System.Linq;
using System.Threading;
using Inprotech.Integration.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers
{
    public class IntegrationDbSetup : IDisposable
    {
        public IntegrationDbSetup(IRepository dbContext = null)
        {
            IntegrationDbContext = dbContext ?? new IntegrationDbContext();
        }

        internal IRepository IntegrationDbContext { get; }

        public virtual void Dispose()
        {
            var integrationDbContext = IntegrationDbContext as IntegrationDbContext;

            integrationDbContext?.Dispose();
        }

        public TEntity Insert<TEntity>(TEntity entity) where TEntity : class
        {
            var r = IntegrationDbContext.Set<TEntity>().Add(entity);

            IntegrationDbContext.SaveChanges();

            return r;
        }

        public void Delete<T>(T entity) where T : class
        {
            IntegrationDbContext.Set<T>().Remove(entity);
            IntegrationDbContext.SaveChanges();
        }

        public static T Do<T>(Func<IntegrationDbSetup, T> func)
        {
            using (var setup = new IntegrationDbSetup())
            {
                return func(setup);
            }
        }

        public static void Do(Action<IntegrationDbSetup> action)
        {
            using (var setup = new IntegrationDbSetup())
            {
                action(setup);
            }
        }

        public static void WaitForAny<T>(Func<T, bool> predicate = null) where T : class
        {
            const int maxWait = 180;
            var currentWait = 0;
            while (currentWait < maxWait)
            {
                var hasRequiredT = Do(x => predicate == null
                                                             ? x.IntegrationDbContext.Set<T>().Any()
                                                             : x.IntegrationDbContext.Set<T>().Any(predicate));

                if (hasRequiredT) break;

                Thread.Sleep(TimeSpan.FromSeconds(1));
                currentWait++;
            }
        }
    }
}