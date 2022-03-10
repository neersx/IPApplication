using Autofac;

namespace Inprotech.Web.Configuration.Ede.DataMapping
{
    public class DataMappingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ConfigurableDataSources>().As<IConfigurableDataSources>();
        }
    }
}
