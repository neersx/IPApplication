using Autofac;

namespace Inprotech.Web.SchemaMapping
{
    public class SchemaMappingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<DocItemReader>().As<IDocItemReader>();
        }
    }
}