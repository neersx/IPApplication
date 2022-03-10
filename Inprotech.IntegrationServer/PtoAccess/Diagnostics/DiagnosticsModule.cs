using Autofac;
using Dependable.Diagnostics;

namespace Inprotech.IntegrationServer.PtoAccess.Diagnostics
{
    public class DiagnosticsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BackgroundAutomationLogger>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<SchedulingRuntimeLogger>().As<IExceptionLogger>();
            builder.RegisterType<RuntimeMessages>().As<IRuntimeMessages>();
            builder.RegisterType<IntegrationServerLogs>().AsImplementedInterfaces();
            builder.RegisterType<RuntimeEvents>().As<IRuntimeEvents>().AsSelf();
            builder.RegisterType<UsptoMissingFiles>().AsImplementedInterfaces();
        }
    }
}