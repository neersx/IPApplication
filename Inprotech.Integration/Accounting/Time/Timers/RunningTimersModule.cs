using Autofac;

namespace Inprotech.Integration.Accounting.Time.Timers
{
    public class RunningTimersModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<StopRunningTimers>().AsSelf();
        }
    }
}
