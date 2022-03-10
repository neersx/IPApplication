using Autofac;

namespace Inprotech.Infrastructure.Legacy
{
    public class LegacyModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<DataService>().As<IDataService>().InstancePerLifetimeScope();
        }
    }
}