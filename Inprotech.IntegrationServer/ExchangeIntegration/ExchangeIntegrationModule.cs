using Autofac;
using Inprotech.Infrastructure;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.IntegrationServer.BackgroundProcessing;

namespace Inprotech.IntegrationServer.ExchangeIntegration
{
    public class ExchangeIntegrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BackgroundTasksProcessor<ExchangeQueueProcessor>>().As<IClock>().SingleInstance();
            builder.RegisterType<ExchangeQueueProcessor>().AsSelf();
            builder.RegisterType<ExchangeRequestQueue>().As<IRequestQueue>();
            builder.RegisterType<ExchangeIntegrationSettings>().As<IExchangeIntegrationSettings>();

            builder.RegisterType<ConfigurationSettings>().As<IConfigurationSettings>();
            
            builder.RegisterType<ExchangeUsageAnalyticsProvider>().As<IAnalyticsEventProvider>();
        }
    }
}