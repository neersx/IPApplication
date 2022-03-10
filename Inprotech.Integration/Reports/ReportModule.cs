using Autofac;
using Inprotech.Integration.Reports.Engine;
using Inprotech.Integration.Reports.Job;
using InprotechKaizen.Model.Components.Reporting;

namespace Inprotech.Integration.Reports
{
    public class ReportModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ReportExecutionHandler>().AsImplementedInterfaces();
            builder.RegisterType<StandardReportExecutionJob>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<ReportService>().As<IReportService>();
            builder.RegisterType<ReportEngine>().AsSelf();
            builder.RegisterType<ReportContentManager>().As<IReportContentManager>();
            builder.RegisterType<ReportClient>().As<IReportClient>();
            builder.RegisterType<ReportClientProvider>().As<IReportClientProvider>();
        }
    }
}
