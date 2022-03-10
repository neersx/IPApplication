using Autofac;

namespace Inprotech.Web.Search.TaskPlanner.SavedSearch
{
    public class TaskPlannerSearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
             builder.RegisterType<TaskPlannerSavedSearch>().As<ITaskPlannerSavedSearch>();
        }
    }
}
