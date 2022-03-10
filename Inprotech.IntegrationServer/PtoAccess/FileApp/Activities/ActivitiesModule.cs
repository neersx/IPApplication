using Autofac;
using Inprotech.Integration;
using Inprotech.IntegrationServer.PtoAccess.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class ActivitiesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DueSchedule>().AsSelf();
            builder.RegisterType<EnsureScheduleValid>().AsSelf();
            builder.RegisterType<DownloadRequired>().AsSelf();
            builder.RegisterType<ResolveEligibleCases>().AsSelf();
            builder.RegisterType<DetailsUnavailableOrInvalid>().AsSelf();
            builder.RegisterType<DownloadedCase>().AsSelf();
            builder.RegisterType<DetailsAvailable>().As<IDetailsAvailable>();
            builder.RegisterType<DownloadCaseDispatcher>().As<IDownloadCaseDispatcher>();
            builder.RegisterType<FileCaseUpdator>().As<IFileCaseUpdator>();

            builder.RegisterType<VersionableContentResolver>()
                   .Keyed<IVersionableContentResolver>(DataSourceType.File);
        }
    }
}