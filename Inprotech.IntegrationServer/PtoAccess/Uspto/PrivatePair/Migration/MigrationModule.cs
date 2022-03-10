using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Migration
{
    public class MigrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BackfillCorrelationId>().AsImplementedInterfaces().AsSelf();
        }
    }
}
