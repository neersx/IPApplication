using Autofac;
using Inprotech.Infrastructure.Diagnostics;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class PtoAccessModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ErrorLogger>().AsSelf();
            builder.RegisterType<GlobErrors>().As<IGlobErrors>();
            builder.RegisterType<DiagnosticLogsProvider>().As<IDiagnosticLogsProvider>();
            builder.RegisterType<InstanceInformation>().AsImplementedInterfaces();
            builder.RegisterType<ScheduleInitialisationIssues>().AsImplementedInterfaces();
            builder.RegisterType<CaseIssues>().AsImplementedInterfaces();
            builder.RegisterType<DocumentIssues>().AsImplementedInterfaces();
            builder.RegisterType<UsptoFileIssues>().AsImplementedInterfaces();
            builder.RegisterType<StoredFiles>().AsImplementedInterfaces();
            builder.RegisterType<IpOneFailures>().AsImplementedInterfaces();
            builder.RegisterType<CurrentFailureSnapshot>().AsImplementedInterfaces();
            builder.RegisterType<DataExtractionLogger>().As<IDataExtractionLogger>();
            builder.RegisterType<LogEntry>().As<ILogEntry>();
        }
    }
}
