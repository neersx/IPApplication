using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class ActivitiesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DueSchedule>().AsSelf();
            builder.RegisterType<NewCaseDetailsAvailableNotification>().AsSelf();
            builder.RegisterType<DocumentUpdate>().As<IDocumentUpdate>();
            builder.RegisterType<DocumentDownload>().As<IDocumentDownload>();
            builder.RegisterType<DetailsWorkflow>().As<IDetailsWorkflow>().AsSelf();
            builder.RegisterType<ApplicationDownloadFailed>().As<IApplicationDownloadFailed>();
            builder.RegisterType<CheckCaseValidity>().As<ICheckCaseValidity>();

            builder.RegisterType<EnsureScheduleValid>().As<IEnsureScheduleValid>();
            builder.RegisterType<Messages>().As<IMessages>();
            builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
            builder.RegisterType<ApplicationList>().As<IApplicationList>();

            builder.RegisterType<BiblioStorage>().As<IBiblioStorage>();
            builder.RegisterType<ProcessApplicationDocuments>().As<IProcessApplicationDocuments>();
            builder.RegisterType<DocumentDownloadFailure>().As<IDocumentDownloadFailure>();
            builder.RegisterType<UpdateArtifactMessageIndex>().As<IUpdateArtifactMessageIndex>();
            builder.RegisterType<DocumentValidation>().AsImplementedInterfaces();
        }
    }
}
