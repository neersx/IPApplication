using Autofac;

namespace InprotechKaizen.Model.Components.Reporting
{
    public class ReportingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ReportProvider>().As<IReportProvider>();
        }
    }
}
