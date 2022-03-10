using Autofac;

namespace Inprotech.Infrastructure.Caching
{
    public class CachingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<LifetimeScopeCache>()
                   .As<ILifetimeScopeCache>()
                   .InstancePerLifetimeScope();
        }
    }
}