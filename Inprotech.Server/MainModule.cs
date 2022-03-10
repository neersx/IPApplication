using System;
using Autofac;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Monitoring;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.IPPlatform.Sso;
using Inprotech.Server.ApplicationInsightsExtensions;
using InprotechKaizen.Model.Components;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Server
{
    public class MainModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<WebSecurityContext>().As<ISecurityContext>().As<ICurrentIdentity>();
            builder.RegisterType<UserAccessToken>().AsImplementedInterfaces().InstancePerRequest();
            builder.RegisterType<CurrentOperationIdProvider>().As<ICurrentOperationIdProvider>().InstancePerRequest();

            builder.RegisterType<CurrentOwinContext>().As<ICurrentOwinContext>();
            builder.Register<Func<HostApplication>>(c => () => new HostApplication("Inprotech.Server"));
        }
    }
}
