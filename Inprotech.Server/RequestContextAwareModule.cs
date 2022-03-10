using Autofac;
using Inprotech.Infrastructure.Localisation;

namespace Inprotech.Server
{
    public class RequestContextAwareModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PreferredCultureResolver>().As<IPreferredCultureResolver>().InstancePerRequest();
        }
    }
}
