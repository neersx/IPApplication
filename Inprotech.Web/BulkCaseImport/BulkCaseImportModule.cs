using Autofac;
using Inprotech.Web.BulkCaseImport.NameResolution;
using Inprotech.Web.BulkCaseImport.Validators;

namespace Inprotech.Web.BulkCaseImport
{
    public class BulkCaseImportModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CpaXmlImport>().As<ICpaXmlImport>();
            builder.RegisterType<ConvertToCpaXml>().As<IConvertToCpaXml>();
            builder.RegisterType<SenderDetailsValidator>().As<ISenderDetailsValidator>();
            builder.RegisterType<CpaXmlToEde>().As<ICpaXmlToEde>();
            builder.RegisterType<SqlXmlBulkLoad>().As<ISqlXmlBulkLoad>();
            builder.RegisterType<BulkLoadProcessing>().As<IBulkLoadProcessing>();
            builder.RegisterType<ImportServer>().As<IImportServer>();
            builder.RegisterType<SqlXmlConnectionStringBuilder>().As<ISqlXmlConnectionStringBuilder>();
            builder.RegisterType<CpaXmlValidator>().As<ICpaXmlValidator>();
            builder.RegisterType<ImportStatusSummary>().As<IImportStatusSummary>();
            builder.RegisterType<NameMapper>().As<INameMapper>();
            builder.RegisterType<CaseImportTemplates>().As<ICaseImportTemplates>();
            builder.RegisterType<XmlIllegalCharSanitiser>().As<IXmlIllegalCharSanitiser>();
        }
    }
}