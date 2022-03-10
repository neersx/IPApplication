using Autofac;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.IntegrationServer
{
    public class IntegrationServerModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<IntegrationServerClient>().As<IIntegrationServerClient>();
            builder.RegisterType<TransientAccessTokenResolver>().As<ITransientAccessTokenResolver>();
            builder.RegisterType<SessionAccessTokenInputResolver>().As<ISessionAccessTokenInputResolver>();
            builder.RegisterType<SessionAccessTokenGenerator>().As<ISessionAccessTokenGenerator>().SingleInstance();
        }
    }
}
