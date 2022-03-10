using Autofac;

namespace Inprotech.Infrastructure.Compatibility
{
    class CompatibilityModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<InprotechVersionChecker>().As<IInprotechVersionChecker>();
        }
    }
}
