using Autofac;

namespace Inprotech.Integration.Schedules
{
    public class SchedulesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PopulateNextRun>().As<IPopulateNextRun>();
            builder.RegisterType<UpdateScheduleState>().As<IUpdateScheduleState>();
            builder.RegisterType<ScheduleRuntimeEvents>().As<IScheduleRuntimeEvents>();
            builder.RegisterType<ArtifactsService>().As<IArtifactsService>();
            builder.RegisterType<ScheduleExecutionRootResolver>().AsImplementedInterfaces();
            builder.RegisterType<ScheduleExecutions>().AsImplementedInterfaces();
            builder.RegisterType<RecoverableItems>().AsImplementedInterfaces();
            builder.RegisterType<RecoveryScheduleStatusReader>().AsImplementedInterfaces();
            builder.RegisterType<RecoveryInfoManager>().AsImplementedInterfaces();
            builder.RegisterType<ScheduleExecutionManager>().AsImplementedInterfaces();
            builder.RegisterType<ScheduleRecoverableReader>().As<IScheduleRecoverableReader>();
            builder.RegisterType<RecoverableSchedule>().As<IRecoverableSchedule>();
            builder.RegisterType<FailureSummaryProvider>().As<IFailureSummaryProvider>();
            builder.RegisterType<ScheduleDetails>().As<IScheduleDetails>();
        }
    }
}
