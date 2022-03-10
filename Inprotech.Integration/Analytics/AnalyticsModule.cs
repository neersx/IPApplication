using Autofac;

namespace Inprotech.Integration.Analytics
{
    internal class AnalyticsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<TransactionalAnalyticsProviderSink>().AsImplementedInterfaces().SingleInstance();

            builder.RegisterType<TrackedEventPersistence>().AsImplementedInterfaces();

            builder.RegisterType<ServerTransactionDataQueue>().As<IServerTransactionDataQueue>();

            builder.RegisterType<ProductImprovementSettingsResolver>().As<IProductImprovementSettingsResolver>().SingleInstance();
        }
    }
}