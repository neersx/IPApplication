using Autofac;
using Inprotech.IntegrationServer.BackgroundProcessing;
using Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.DeliverAsDraftEmail;
using Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.PdfViaReportingServices;

namespace Inprotech.IntegrationServer.DocumentGeneration
{
    public class DocumentGenerationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<BackgroundTasksProcessor<DocGenRequestProcessor>>().As<IClock>().SingleInstance();
            builder.RegisterType<DocGenRequestProcessor>().AsSelf();
            builder.RegisterType<RequestQueue>().As<IRequestQueue>();
            builder.RegisterType<StorageLocationResolver>().As<IStorageLocationResolver>();
            builder.RegisterType<SettingsResolver>().As<ISettingsResolver>().InstancePerLifetimeScope();

            builder.RegisterType<PdfViaReportingServicesHandler>()
                   .Keyed<IHandleDocGenRequest>(TypeOfRequest.CreatePdfReportingServices);

            builder.RegisterType<DeliverAsDraftEmailHandler>()
                   .Keyed<IHandleDocGenRequest>(TypeOfRequest.DeliverDraftEmail);
        }
    }
}