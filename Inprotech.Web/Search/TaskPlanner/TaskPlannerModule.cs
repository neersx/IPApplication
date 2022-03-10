using Autofac;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.TaskPlanner
{
    public class TaskPlannerModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<LastWorkingDayFinder>().As<ILastWorkingDayFinder>();

            builder.RegisterType<TaskPlannerXmlFilterCriteriaBuilder>()
                   .Keyed<IXmlFilterCriteriaBuilder>(QueryContext.TaskPlanner);

            builder.RegisterType<TaskPlannerFilterableColumnsMap>()
                   .Keyed<IFilterableColumnsMap>(QueryContext.TaskPlanner);

            builder.RegisterType<ReminderDetailsResolver>().As<IReminderDetailsResolver>();
            builder.RegisterType<ReminderCommentsService>().As<IReminderComments>();
            builder.RegisterType<ReminderManager>().As<IReminderManager>();
            builder.RegisterType<TaskPlannerRowSelectionService>().As<ITaskPlannerRowSelectionService>();
            builder.RegisterType<ForwardReminderHandler>().As<IForwardReminderHandler>();
            builder.RegisterType<TaskPlannerTabResolver>().As<ITaskPlannerTabResolver>();
        }
    }
}