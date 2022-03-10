using Autofac;

namespace Inprotech.Integration.Email
{
    public class EmailModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<EventNotesMailMessageExecution>().AsSelf();
            builder.RegisterType<EventNotesMailMessageHandler>().AsImplementedInterfaces();
            builder.RegisterType<EventNotesMailMessagePerformJob>().AsImplementedInterfaces();
        }
    }
}