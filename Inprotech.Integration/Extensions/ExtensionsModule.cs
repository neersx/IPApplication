using Autofac;

namespace Inprotech.Integration.Extensions
{
    public class ExtensionsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            
            builder.RegisterType<NullActivity>().AsSelf();
        }
    }
}
