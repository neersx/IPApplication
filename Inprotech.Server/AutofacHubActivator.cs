using System;
using Autofac;
using Microsoft.AspNet.SignalR.Hubs;

namespace Inprotech.Server
{
    public class AutofacHubActivator : IHubActivator
    {
        readonly ILifetimeScope _container;

        public AutofacHubActivator(ILifetimeScope container)
        {
            _container = container;
        }

        public IHub Create(HubDescriptor descriptor)
        {
            if (descriptor == null) throw new ArgumentNullException(nameof(descriptor));

            return (IHub)_container.Resolve(descriptor.HubType);
        }
    }
}