using Autofac;

namespace Inprotech.Integration.DocumentGeneration
{
    public class DocumentGenerationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<PdfDocumentCache>().As<IPdfDocumentCache>().SingleInstance();
            builder.RegisterType<PdfForm>().As<IPdfForm>();
            builder.RegisterType<PdfFormFillService>().As<IPdfFormFillService>();
        }
    }
}