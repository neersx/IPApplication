using Autofac;

namespace Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.PdfViaReportingServices
{
    public class PdfViaReportingServicesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PdfReportRequestResolver>().As<IPdfReportRequestResolver>();
        }
    }
}