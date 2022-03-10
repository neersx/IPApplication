using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    class DmsIntegrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CaseAndDocumentLoader>().AsImplementedInterfaces();
            builder.RegisterType<DmsIntegrationWorkflow>().AsImplementedInterfaces();
            builder.RegisterType<MoveDocumentToDmsFolder>().AsImplementedInterfaces();
            builder.RegisterType<DocumentStatusUpdater>().AsImplementedInterfaces();
            builder.RegisterType<WriteDocumentsToDestination>().AsImplementedInterfaces();
            builder.RegisterType<DmsIntegrationWorkflow>().AsImplementedInterfaces();
            builder.RegisterType<PtoAccessDocumentLocationResolver>().AsImplementedInterfaces();
            builder.RegisterType<DocumentSendToDmsFailure>().AsImplementedInterfaces();
            builder.RegisterType<CaseLoaderAndDocumentSender>().AsImplementedInterfaces();
            builder.RegisterType<DmsIntegrationJobStateUpdater>().AsImplementedInterfaces();
            builder.RegisterType<SendSelectedDocumentsToDms>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<SendPrivatePairDocumentsToDms>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<SendTsdrDocumentsToDms>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<DmsIntegrationLogger>().AsImplementedInterfaces();
            builder.RegisterType<DmsIntegrationPublisher>().As<IDmsIntegrationPublisher>();
            builder.RegisterType<DocumentForDms>().As<IDocumentForDms>();
        }
    }
}
