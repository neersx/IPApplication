using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Extensibility
{
    public class ExtensibilityModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            
            builder.RegisterType<PrivatePairRuntimeEvents>().As<IPrivatePairRuntimeEvents>();
        }
    }
}
