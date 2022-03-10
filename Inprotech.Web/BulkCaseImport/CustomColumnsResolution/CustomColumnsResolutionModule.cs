using Autofac;

namespace Inprotech.Web.BulkCaseImport.CustomColumnsResolution
{
    public class CustomColumnsResolutionModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CustomColumnsResolver>().As<ICustomColumnsResolver>();
            builder.RegisterType<StructureMappingResolver>().As<IStructureMappingResolver>();
        }
    }
}
