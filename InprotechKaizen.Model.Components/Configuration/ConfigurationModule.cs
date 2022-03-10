using Autofac;
using InprotechKaizen.Model.Components.Configuration.SiteControl;

namespace InprotechKaizen.Model.Components.Configuration
{
    public class ConfigurationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<SiteConfiguration>().As<ISiteConfiguration>().InstancePerLifetimeScope();
            builder.RegisterType<AvailableTopicsReader>().As<IAvailableTopicsReader>();
        }
    }
}
