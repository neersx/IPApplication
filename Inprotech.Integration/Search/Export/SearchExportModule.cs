using Autofac;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Integration.Search.Export.Jobs;

namespace Inprotech.Integration.Search.Export
{
    public class SearchExportModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            // export job
            builder.RegisterType<ExportExecutionHandler>().AsImplementedInterfaces();
            builder.RegisterType<ExportExecutionJob>().AsImplementedInterfaces().AsSelf();

            // export execution engine components
            builder.RegisterType<ExportExecutionEngine>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<ImageSettingsLoader>().As<IImageSettings>();
            builder.RegisterType<UserColumnUrlResolver>().As<IUserColumnUrlResolver>();
            builder.RegisterType<SearchResultsExport>().As<ISearchResultsExport>();
        }
    }
}
