using Autofac;

namespace Inprotech.Web.Processing
{
    public class ProcessingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<ServiceBrokerStatusMonitor>().As<IServiceBrokerStatusMonitor>();
            builder.RegisterType<TranslationChangeMonitor>().As<ITranslationChangeMonitor>();
            builder.RegisterType<CpaXmlExporter>().As<ICpaXmlExporter>();
        }
    }
}
