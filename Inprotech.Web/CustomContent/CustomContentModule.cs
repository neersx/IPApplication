using Autofac;

namespace Inprotech.Web.CustomContent
{
    public class CustomContentModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CustomContentDataResolver>().As<ICustomContentDataResolver>();
        }
    }
}