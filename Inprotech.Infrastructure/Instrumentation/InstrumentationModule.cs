using Autofac;

namespace Inprotech.Infrastructure.Instrumentation
{
    public class InstrumentationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ApplicationInsights>().As<IApplicationInsights>();
            builder.RegisterType<AnalyticsRuntimeSettings>().AsSelf().SingleInstance();
        }
    }
}