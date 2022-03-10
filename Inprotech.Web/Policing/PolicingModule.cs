using Autofac;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;

namespace Inprotech.Web.Policing
{
    public class PolicingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PolicingQueue>().As<IPolicingQueue>();
            builder.RegisterType<ErrorReader>().As<IErrorReader>();
            builder.RegisterType<DashboardDataProvider>().As<IDashboardDataProvider>();
            builder.RegisterType<DashboardSubscriptions>().As<IDashboardSubscriptions>();
            builder.RegisterType<PolicingDashboardMonitor>().As<IPolicingDashboardMonitor>().SingleInstance();
            builder.RegisterType<PolicingServerMonitor>().As<IPolicingServerMonitor>();
            builder.RegisterType<PolicingBackgroundServer>().As<IPolicingBackgroundServer>();
            builder.RegisterType<PolicingRequestLogReader>().As<IPolicingRequestLogReader>();
            builder.RegisterType<RequestLogErrorReader>().As<IRequestLogErrorReader>();
            builder.RegisterType<PolicingRequestReader>().As<IPolicingRequestReader>();
            builder.RegisterType<PolicingErrorLog>().As<IPolicingErrorLog>();
            builder.RegisterType<PolicingRequestDateCalculator>().As<IPolicingRequestDateCalculator>();
            builder.RegisterType<PolicingCharacteristicsService>().As<IPolicingCharacteristicsService>();
            builder.RegisterType<PolicingAffectedCasesSubscriptions>().AsImplementedInterfaces().SingleInstance();
            builder.RegisterType<PolicingAffectedCasesMonitor>().As<IPolicingAffectedCasesMonitor>();
        }
    }
}
