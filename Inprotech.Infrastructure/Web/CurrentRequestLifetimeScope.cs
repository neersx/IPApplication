using System;
using System.Net.Http;
using System.Web.Http.Hosting;
using Autofac;
using Autofac.Core;
using Autofac.Integration.Owin;
using Autofac.Integration.WebApi;
using Inprotech.Infrastructure.Hosting;

namespace Inprotech.Infrastructure.Web
{
    public interface ICurrentRequestLifetimeScope
    {
        T Resolve<T>(HttpRequestMessage httpRequestMessage = null);

        bool TryResolve(Type typeToResolve, out object component, HttpRequestMessage httpRequestMessage = null);
    }

    public class CurrentRequestLifetimeScope : ICurrentRequestLifetimeScope
    {
        readonly ICurrentOwinContext _currentOwinContext;
        readonly ILifetimeScope _lifetimeScope;

        public CurrentRequestLifetimeScope(ICurrentOwinContext currentOwinContext, ILifetimeScope lifetimeScope)
        {
            _currentOwinContext = currentOwinContext;
            _lifetimeScope = lifetimeScope;
        }

        public T Resolve<T>(HttpRequestMessage httpRequestMessage = null)
        {
            return GetDependencyScope(httpRequestMessage).Resolve<T>();
        }

        public bool TryResolve(Type typeToResolve, out object component, HttpRequestMessage httpRequestMessage = null)
        {
            try
            {
                return GetDependencyScope().TryResolve(typeToResolve, out component);
            }
            catch (DependencyResolutionException)
            {
                component = null;
                return false;
            }
        }

        ILifetimeScope GetDependencyScope(HttpRequestMessage httpRequestMessage = null)
        {
            if (httpRequestMessage != null)
            {
                var dependencyScope = (AutofacWebApiDependencyScope) httpRequestMessage.Properties[HttpPropertyKeys.DependencyScope];
                return dependencyScope.LifetimeScope;
            }

            return _currentOwinContext.OwinContext?.GetAutofacLifetimeScope() ?? _lifetimeScope;
        }
    }
}