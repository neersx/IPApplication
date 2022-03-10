using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Activities
{
    public class ActivitiesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ScheduleInitialisationFailure>().AsSelf();
            builder.RegisterType<DownloadFailedNotification>().As<IDownloadFailedNotification>();
            builder.RegisterType<DownloadDocumentFailed>().AsSelf();
            builder.RegisterType<NewCaseDetailsNotification>()
                   .As<INewCaseDetailsNotification>()
                   .AsSelf();

            builder.RegisterType<BackgroundIdentityConfiguration>().AsSelf();

            builder.RegisterType<ChunckedDownloadRequests>().As<IChunckedDownloadRequests>();
            builder.RegisterType<CasesEligibleForDownload>().As<ICasesEligibleForDownload>();
            builder.RegisterType<CommonSettings>().As<ICommonSettings>();
            builder.RegisterType<PtoDocument>().As<IPtoDocument>();
        }
    }
}