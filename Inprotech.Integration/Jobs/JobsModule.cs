using Autofac;
using Inprotech.Integration.Accounting.Time.Timers;

namespace Inprotech.Integration.Jobs
{
    public class JobsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DailySystemVerification>().As<IPerformBackgroundJob>();
            builder.RegisterType<RunningTimersJob>().As<IPerformBackgroundJob>();
        }
    }
}