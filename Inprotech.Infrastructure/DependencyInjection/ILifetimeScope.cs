using System;

namespace Inprotech.Infrastructure.DependencyInjection
{
    public interface ILifetimeScope : IDisposable
    {
        ILifetimeScope BeginLifetimeScope();

        T Resolve<T>();

        T ResolveNamed<T>(string name);

        T ResolveKeyed<T>(object key);

        bool TryResolve<T>(out T value);
    }
}