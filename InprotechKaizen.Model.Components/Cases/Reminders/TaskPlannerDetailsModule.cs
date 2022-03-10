using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Reminders
{
    public class TaskPlannerDetailsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<TaskPlannerDetailsResolver>().As<ITaskPlannerDetailsResolver>();
            builder.RegisterType<TaskPlannerEmailResolver>().As<ITaskPlannerEmailResolver>();
        }
    }
}
