using Autofac;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;

namespace Inprotech.Web.Exporters
{
    class ExportersModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ExportConfigProvider>().As<IExportConfigProvider>().SingleInstance();

            builder.RegisterType<UserAwareExportHelperService>().As<IExportHelperService>().InstancePerLifetimeScope();
        }
    }
}
