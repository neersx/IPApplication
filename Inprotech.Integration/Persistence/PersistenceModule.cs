using Autofac;

namespace Inprotech.Integration.Persistence
{
    public class PersistenceModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<IntegrationDbContext>().As<IRepository>().InstancePerLifetimeScope();
        }
    }
}