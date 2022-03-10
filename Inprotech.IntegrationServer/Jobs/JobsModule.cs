using Autofac;
using Inprotech.IntegrationServer.BackgroundProcessing;

namespace Inprotech.IntegrationServer.Jobs
{
    public class JobsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<JobRunner>().As<IJobRunner>();

            builder.RegisterType<PendingJobsInterrupter>()
                .Named<IInterrupter>(typeof(PendingJobsInterrupter).Name);

            builder.RegisterType<JobExecutionStatusManager>().AsImplementedInterfaces();
        }
    }
}