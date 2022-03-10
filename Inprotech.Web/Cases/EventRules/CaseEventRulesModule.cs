using Autofac;

namespace Inprotech.Web.Cases.EventRules
{
    public class CaseEventRulesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<EventRulesService>().As<IEventRulesService>();
            builder.RegisterType<DueDateCalculationService>().As<IDueDateCalculationService>();
            builder.RegisterType<RemindersService>().As<IRemindersService>();
            builder.RegisterType<DocumentsService>().As<IDocumentsService>();
            builder.RegisterType<EventRulesHelper>().As<IEventRulesHelper>();
            builder.RegisterType<DatesLogicService>().As<IDatesLogicService>();
            builder.RegisterType<EventUpdateDetailsService>().As<IEventUpdateDetailsService>();
        }
    }
}
