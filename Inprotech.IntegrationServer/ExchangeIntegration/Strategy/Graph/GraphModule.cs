using Autofac;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes;
using InprotechKaizen.Model.Components.System.BackgroundProcess;

namespace Inprotech.IntegrationServer.ExchangeIntegration.Strategy.Graph
{
    public class GraphModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<GraphClient>()
                   .Keyed<IExchangeService>(KnownImplementations.Graph);
            builder.RegisterType<GraphHttpClient>().As<IGraphHttpClient>();
            builder.RegisterType<AppSettings>().As<IAppSettings>();
            builder.RegisterType<GraphAccessTokenManager>().As<IGraphAccessTokenManager>();
            builder.RegisterType<BackgroundProcessMessageClient>().As<IBackgroundProcessMessageClient>();
            builder.RegisterType<GraphNotification>().As<IGraphNotification>();
            builder.RegisterType<GraphTaskIdCache>().As<IGraphTaskIdCache>();
        }
    }
}
