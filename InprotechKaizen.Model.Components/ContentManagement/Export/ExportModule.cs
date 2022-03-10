using Autofac;

namespace InprotechKaizen.Model.Components.ContentManagement.Export
{
    public class ExportModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ExportContentStatusReader>().AsImplementedInterfaces();
            builder.RegisterType<ExportContentDataProvider>().AsImplementedInterfaces().SingleInstance();
            builder.RegisterType<ExportExecutionTimeLimit>().As<IExportExecutionTimeLimit>();
        }
    }
}
