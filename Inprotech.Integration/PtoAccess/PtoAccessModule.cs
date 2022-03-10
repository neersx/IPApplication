using Autofac;

namespace Inprotech.Integration.PtoAccess
{
    public class PtoAccessModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<UsptoMessageFileLocationResolver>().AsImplementedInterfaces();
        }
    }
}
