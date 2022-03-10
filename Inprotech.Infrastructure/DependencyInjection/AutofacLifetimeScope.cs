using System.Diagnostics.CodeAnalysis;
using Autofac;
using Autofac.Core;

namespace Inprotech.Infrastructure.DependencyInjection
{
    [SuppressMessage("Microsoft.Design", "CA1063:ImplementIDisposableCorrectly")]
    [SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Autofac")]
    public class AutofacLifetimeScope : ILifetimeScope
    {
        readonly Autofac.ILifetimeScope _currentLifetimeScope;

        public AutofacLifetimeScope(Autofac.ILifetimeScope currentLifetimeScope)
        {
            _currentLifetimeScope = currentLifetimeScope;
        }

        public ILifetimeScope BeginLifetimeScope()
        {
            return new AutofacLifetimeScope(_currentLifetimeScope.BeginLifetimeScope());
        }

        public T Resolve<T>()
        {
            return _currentLifetimeScope.Resolve<T>();
        }

        public T ResolveNamed<T>(string name)
        {
            return _currentLifetimeScope.ResolveNamed<T>(name);
        }

        public T ResolveKeyed<T>(object key)
        {
            return _currentLifetimeScope.ResolveKeyed<T>(key);
        }

        public bool TryResolve<T>(out T value)
        {
            try
            {
                return _currentLifetimeScope.TryResolve<T>(out value);
            }
            catch (DependencyResolutionException)
            {
                value = default(T);
                return false;
            }
        }

        [SuppressMessage("Microsoft.Design", "CA1063:ImplementIDisposableCorrectly")]
        public void Dispose()
        {
            _currentLifetimeScope.Dispose();
        }
    }
}