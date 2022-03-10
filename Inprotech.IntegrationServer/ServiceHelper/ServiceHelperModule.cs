using Autofac;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;

namespace Inprotech.IntegrationServer.ServiceHelper
{
    public class ServiceHelperModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BackgroundProcessExportHelperService>().As<IExportHelperService>();
        }
    }
}
