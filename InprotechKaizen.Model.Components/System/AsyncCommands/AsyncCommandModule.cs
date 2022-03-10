using Autofac;
using Inprotech.Infrastructure.Processing;

namespace InprotechKaizen.Model.Components.System.AsyncCommands
{
    public class AsyncCommandModule : Autofac.Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<ServiceBrokerQuery>().As<IServiceBrokerQuery>();
            builder.RegisterType<AsyncCommandScheduler>().As<IAsyncCommandScheduler>();
        }
    }
}
