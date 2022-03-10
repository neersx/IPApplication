using Autofac;

namespace Inprotech.Integration.DmsIntegration
{
    public class DmsIntegrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<MetadataBuilder>().AsImplementedInterfaces();
            builder.RegisterType<DownloadStatusCalculator>().AsImplementedInterfaces();
            builder.RegisterType<DataSourceLocationResolver>().AsImplementedInterfaces();
            builder.RegisterType<DmsFilenameFormatter>().AsImplementedInterfaces();
            builder.RegisterType<DmsEventSink>().AsImplementedInterfaces().InstancePerLifetimeScope();
            builder.RegisterType<DmsEventEmitter>().As<IDmsEventEmitter>();
        }
    }
}
