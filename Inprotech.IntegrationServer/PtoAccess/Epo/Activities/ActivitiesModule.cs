using Autofac;
using Inprotech.Integration;
using Inprotech.IntegrationServer.PtoAccess.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.Activities
{
    public class ActivitiesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DueSchedule>().AsSelf();
            builder.RegisterType<EnsureScheduleValid>().AsSelf();
            builder.RegisterType<ResolveEligibleCases>().AsSelf();
            builder.RegisterType<DownloadCase>().AsSelf();
            builder.RegisterType<DownloadRequired>().AsSelf();
            builder.RegisterType<DetailsAvailable>().AsSelf();
            builder.RegisterType<DocumentList>().AsSelf();
            builder.RegisterType<DownloadDocument>().AsSelf();

            builder.RegisterType<VersionableContentResolver>()
                .Keyed<IVersionableContentResolver>(DataSourceType.Epo);
        }
    }
}