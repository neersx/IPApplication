using Autofac;

namespace Inprotech.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter
{
    public class HtmlBodyConverterModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<ConvertWordDocToHtml>().As<IConvertWordDocToHtml>();

            builder.RegisterType<HtmlBodyFromWordDocumentConverter>()
                   .Keyed<IHtmlBodyConverter>(Category.Word);
        }
    }
}