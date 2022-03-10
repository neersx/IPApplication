using Autofac;

namespace Inprotech.Integration.SchemaMapping.Migration
{
    public class MigrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<SchemaPackageJobHandler>().As<ISchemaPackageJobHandler>();
            builder.RegisterType<SchemaPackageMigrationJob>().AsImplementedInterfaces().AsSelf();
        }
    }
}