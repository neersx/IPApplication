using Autofac;

namespace InprotechKaizen.Model.Components.Integration.ReportingServices
{
    public class ReportingServicesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ReportingServicesSettingsResolver>()
                   .As<IReportingServicesSettingsPersistence>()
                   .As<IReportingServicesSettingsResolver>()
                   .InstancePerLifetimeScope();
        }
    }
}
