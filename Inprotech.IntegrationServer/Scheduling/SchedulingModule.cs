using Autofac;
using Inprotech.IntegrationServer.BackgroundProcessing;

namespace Inprotech.IntegrationServer.Scheduling
{
    public class SchedulingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<PendingScheduleInterrupter>()
                    .Named<IInterrupter>(typeof(PendingScheduleInterrupter).Name);

            builder.RegisterType<ScheduleRunner>().As<IScheduleRunner>();
            builder.RegisterType<SchedulePreInitialisationFailed>().AsSelf();
            builder.RegisterType<PreinitialisationFailureHandler>().AsSelf();
            builder.RegisterType<ScheduleExecutionResolver>().AsSelf();
        }
    }
}