using Autofac;

namespace InprotechKaizen.Model.Components.Integration.Jobs
{
    public class JobsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<JobArgsStorage>().As<IJobArgsStorage>();
        }
    }
}
