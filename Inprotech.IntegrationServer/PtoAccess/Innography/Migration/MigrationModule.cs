using Autofac;
using Inprotech.Integration.Jobs;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Migration
{
    public class MigrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<NotificationForInactiveInnographyLink>()
                .AsSelf()
                .As<IPerformBackgroundJob>();
        }
    }
}