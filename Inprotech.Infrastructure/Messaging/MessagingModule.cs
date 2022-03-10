using Autofac;

namespace Inprotech.Infrastructure.Messaging
{
    public class MessagingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<Bus>().As<IBus>()
                   .SingleInstance();

        }
    }
}
