using System;
using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Integration.IPPlatform.Sso;
using Inprotech.IntegrationServer.Security;
using InprotechKaizen.Model.Components;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.IntegrationServer
{
    public class MainModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.Register(c => DateTime.Now);

            builder.RegisterType<AppSettingsProvider>().As<IAppSettingsProvider>();
            builder.RegisterType<NameAttributeLoader>().As<INameAttributeLoader>();
            builder.RegisterType<MockCurrentOwinContext>().As<ICurrentOwinContext>();

            builder.RegisterType<WebSecurityContext>().AsSelf();

            builder.RegisterType<BackgroundProcessSecurityContext>()
                .As<ISecurityContext>()
                .As<ICurrentIdentity>()
                .InstancePerLifetimeScope();
            
            builder.RegisterType<ApplicationAccessToken>().As<IAccessTokenProvider>();

            builder.RegisterType<DependableSettingsProvider>().As<IDependableSettings>();

            builder.Register<Func<HostApplication>>(c => () => new HostApplication("Inprotech.IntegrationServer"));
        }
    }
}