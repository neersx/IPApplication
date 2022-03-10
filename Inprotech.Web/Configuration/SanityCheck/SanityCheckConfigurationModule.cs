using Autofac;

namespace Inprotech.Web.Configuration.SanityCheck
{
    public class SanityCheckConfigurationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<SanityCheckService>().As<ISanityCheckService>();
        }
    }
}