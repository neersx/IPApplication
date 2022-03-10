using Autofac;

namespace Inprotech.Web.Messaging
{
    public class MessagingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<ClientMessageBrokerHub>().AsSelf();
            builder.RegisterType<ClientMessageBroker>().AsImplementedInterfaces();
            builder.RegisterType<ClientSubscriptions>().AsImplementedInterfaces().SingleInstance();
            builder.RegisterType<ChannelEventDispatcher>().AsImplementedInterfaces();
        }
    }
}
