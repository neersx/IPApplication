using Autofac;
using Inprotech.Integration.PtoAccess;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.MessageQueueMonitor
{
    class DequeueJobModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DequeueUsptoMessagesJob>().AsImplementedInterfaces();
            builder.RegisterType<StoreDequeuedMessagesFromFileJob>().AsImplementedInterfaces();
            builder.RegisterType<CleanupMessageStoreJob>().AsImplementedInterfaces();
        }
    }
}