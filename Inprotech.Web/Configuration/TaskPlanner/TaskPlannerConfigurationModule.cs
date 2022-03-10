using Autofac;
using Inprotech.Web.Search.TaskPlanner;

namespace Inprotech.Web.Configuration.TaskPlanner
{
    public class TaskPlannerConfigurationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<TaskPlannerConfigurationController>().AsSelf();
            builder.RegisterType<TaskPlannerTabResolver>().As<ITaskPlannerTabResolver>();
        }
    }
}
