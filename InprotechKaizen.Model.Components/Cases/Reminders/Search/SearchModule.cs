using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Reminders.Search
{
    public class SearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            
            builder.RegisterType<TaskPlannerFilterCriteriaBuilder>().As<ITaskPlannerFilterCriteriaBuilder>();
        }
    }
}