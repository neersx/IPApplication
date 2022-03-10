using Autofac;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public class ExportersModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SimpleExcelExporter>().As<ISimpleExcelExporter>();
        }
    }
}
