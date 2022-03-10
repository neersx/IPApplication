using Autofac;

namespace InprotechKaizen.Model.Components.System.BackgroundProcess
{
    public class BackgroundProcessModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BackgroundProcessMessageClient>().AsImplementedInterfaces();
            builder.RegisterType<BackgroundNotificationUsernameProvider>().AsImplementedInterfaces().SingleInstance();
            builder.RegisterType<BackgroundNotificationMonitor>().AsImplementedInterfaces();
            builder.RegisterType<HandleBackgroundNotificationMessage>().As<IHandleBackgroundNotificationMessage>();
        }
    }
}