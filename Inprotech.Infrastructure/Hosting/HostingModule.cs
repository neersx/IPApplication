using Autofac;

namespace Inprotech.Infrastructure.Hosting
{
    public class HostingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<InstanceRegistrations>().As<IInstanceRegistrations>();
            builder.RegisterType<SourceIpAddressResolver>().As<ISourceIpAddressResolver>();
        }
    }
}