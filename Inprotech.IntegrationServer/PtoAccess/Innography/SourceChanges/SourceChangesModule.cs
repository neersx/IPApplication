using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.SourceChanges
{
    public class SourceChangesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<MostRecentlyAppliedChanges>()
                   .As<IMostRecentlyAppliedChanges>();
        }
    }
}