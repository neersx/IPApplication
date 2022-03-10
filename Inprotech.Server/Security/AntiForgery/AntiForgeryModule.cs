using Autofac;
using Inprotech.Infrastructure.Security.AntiForgery;

namespace Inprotech.Server.Security.AntiForgery
{
    public class AntiForgeryModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CsrfConfigOptions>().AsSelf().SingleInstance();
        }
    }
}
