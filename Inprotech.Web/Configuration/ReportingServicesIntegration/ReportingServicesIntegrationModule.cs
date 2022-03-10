using Autofac;

namespace Inprotech.Web.Configuration.ReportingServicesIntegration
{
    public class ReportingServicesIntegrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<ReportingServicesSettingController>().AsSelf();
        }
    }
}
