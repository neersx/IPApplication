using Autofac;

namespace Inprotech.Infrastructure.DependencyInjection
{
    public class DependencyInjectionModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<AutofacLifetimeScope>().As<ILifetimeScope>();
        }
    }
}
