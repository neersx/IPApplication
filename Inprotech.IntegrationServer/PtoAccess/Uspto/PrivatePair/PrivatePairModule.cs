using Autofac;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.MissingDocuments;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class PrivatePairModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<ArtifactsLocationResolver>().As<IArtifactsLocationResolver>();
            builder.RegisterType<InprotechCaseResolver>().As<IInprotechCaseResolver>();
            builder.RegisterType<RecoveryDocumentManager>().As<IProvideDocumentsToRecover>();
            builder.RegisterType<RecoveryApplicationNumbersProvider>().As<IProvideApplicationNumbersToRecover>();
            builder.RegisterType<ScheduleDocumentStartDate>().As<IScheduleDocumentStartDate>();
            builder.RegisterType<ComparisonDocumentsProvider>().As<IComparisonDocumentsProvider>();
            builder.RegisterType<RecoveryRelevantDocumentsFilter>()
                .As<IRelevantDocumentsFilter>()
                .Named<IRelevantDocumentsFilter>(DownloadActivityType.RecoverDocuments.ToString())
                .WithMetadata("Name", DownloadActivityType.RecoverDocuments.ToString());
            builder.RegisterType<CorrelationIdUpdator>().As<ICorrelationIdUpdator>();
            builder.RegisterType<CaseCorrelationResolver>().As<ICaseCorrelationResolver>();

            builder.RegisterType<PtoFailureLogger>().As<IPtoFailureLogger>();
            builder.RegisterType<FileNameExtractor>().As<IFileNameExtractor>();
            builder.RegisterType<SponsorshipHealthCheck>().As<ISponsorshipHealthCheck>();
            builder.RegisterType<ScheduleInitialisationFailure>().As<IScheduleInitialisationFailure>();
            builder.RegisterType<RequeueMessageDates>().As<IRequeueMessageDates>();

            builder.RegisterType<FindMissingDocumentsJob>().AsSelf().AsImplementedInterfaces();
        }
    }
}