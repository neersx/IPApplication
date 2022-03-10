using Autofac;

namespace Inprotech.Integration.ExchangeIntegration
{
    public class ExchangeIntegrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<GraphAccessTokenManager>().As<IGraphAccessTokenManager>();
            builder.RegisterType<ExchangeIntegrationSettings>().As<IExchangeIntegrationSettings>();
            builder.RegisterType<GraphNotification>().As<IGraphNotification>();
            builder.RegisterType<GraphResourceIdManager>().As<IGraphResourceManager>();
            builder.RegisterType<GraphTaskIdCache>().As<IGraphTaskIdCache>();
            builder.RegisterType<GraphHttpClient>().As<IGraphHttpClient>();
            builder.RegisterType<AppSettings>().As<IAppSettings>();
            builder.RegisterType<GraphAccessTokenManager>().As<IGraphAccessTokenManager>();
        }
    }
}
