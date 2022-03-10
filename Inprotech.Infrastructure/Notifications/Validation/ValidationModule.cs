using Autofac;

namespace Inprotech.Infrastructure.Notifications.Validation
{
    public class ApplicationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ApplicationAlerts>().As<IApplicationAlerts>();
        }
    }
}