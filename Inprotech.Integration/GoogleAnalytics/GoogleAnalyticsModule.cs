using Autofac;

namespace Inprotech.Integration.GoogleAnalytics
{
    public class GoogleAnalyticsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ServerAnalyticsJob>().AsSelf().AsImplementedInterfaces();
            builder.RegisterType<EventRequest>().As<IGoogleAnalyticsRequest>();
            builder.RegisterType<GoogleAnalyticsSettingsResolver>().As<IGoogleAnalyticsSettingsResolver>();
            builder.RegisterType<GoogleAnalyticsClient>().As<IGoogleAnalyticsClient>();

            builder.RegisterType<AnalyticsIdentifierResolver>().As<IAnalyticsIdentifierResolver>();
        }
    }
}