using Autofac;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public class EventControlMaintenanceModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DueDateCalcService>().As<IDueDateCalcService>();

            builder.RegisterType<DueDateCalcMaintenance>().As<IEventSectionMaintenance>();
            builder.RegisterType<DateComparison>().As<IEventSectionMaintenance>();
            builder.RegisterType<DateEntryRules>().As<IEventSectionMaintenance>();
            builder.RegisterType<DesignatedJurisdictions>().As<IEventSectionMaintenance>();

            // Satisfying Event, Events To Update, and Events To Clear
            builder.RegisterType<RelatedEvent>().As<IEventSectionMaintenance>();
            builder.RegisterType<RelatedEventService>().As<IRelatedEventService>();

            builder.RegisterType<ReminderAndDocument>().As<IEventSectionMaintenance>();
            builder.RegisterType<NameTypeMapMaintenance>().As<IEventSectionMaintenance>();
            builder.RegisterType<RequiredEventRules>().As<IEventSectionMaintenance>();
        }
    }
}