using Autofac;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Inprotech.Integration.SchemaMapping.XmlGen.Formatters;
using Inprotech.Integration.SchemaMapping.Xsd;

namespace Inprotech.Integration.SchemaMapping
{
    public class SchemaMappingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<XsdService>().AsImplementedInterfaces();
            builder.RegisterType<XsdTreeBuilder>().AsImplementedInterfaces();
            builder.RegisterType<MappingEntryLookup>().AsImplementedInterfaces();
            builder.RegisterType<XDocumentTransformer>().AsImplementedInterfaces();
            builder.RegisterType<LocalContext>().AsImplementedInterfaces();
            builder.RegisterType<GlobalContext>().AsImplementedInterfaces();
            builder.RegisterType<XmlGenTreeTransformer>().AsImplementedInterfaces();
            builder.RegisterType<XmlGenService>().AsImplementedInterfaces();
            builder.RegisterType<XmlValidator>().AsImplementedInterfaces();
            builder.RegisterType<XsdParser>().AsImplementedInterfaces();
            builder.RegisterType<XmlValueFormatter>().AsImplementedInterfaces();
            builder.RegisterType<DateFormatter>().AsImplementedInterfaces();
            builder.RegisterType<DateTimeFormatter>().AsImplementedInterfaces();
            builder.RegisterType<DateYearMonthFormatter>().AsImplementedInterfaces();
            builder.RegisterType<SyncToTableCodes>().AsImplementedInterfaces();
            builder.RegisterType<DtdReader>().AsImplementedInterfaces();
            builder.RegisterType<XmlNamespaceClean>().AsImplementedInterfaces();
        }
    }
}