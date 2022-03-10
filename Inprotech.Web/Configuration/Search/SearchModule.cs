using Autofac;

namespace Inprotech.Web.Configuration.Search
{
    public class SearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ConfigurableItems>().As<IConfigurableItems>();
        }
    }
}