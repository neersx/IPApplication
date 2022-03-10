using Autofac;
using Inprotech.Web.Cases.AssignmentRecordal;
using Inprotech.Web.Cases.Details;

namespace Inprotech.Web.CaseSupportData
{
    public class CaseSupportDataModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<CaseTypes>().As<ICaseTypes>();
            builder.RegisterType<CaseStatuses>().As<ICaseStatuses>();
            builder.RegisterType<PropertyTypes>().As<IPropertyTypes>();
            builder.RegisterType<CaseCategories>().As<ICaseCategories>();
            builder.RegisterType<SubTypes>().As<ISubTypes>();
            builder.RegisterType<Basis>().As<IBasis>();
            builder.RegisterType<Actions>().As<IActions>();
            builder.RegisterType<DateOfLaw>().As<IDateOfLaw>();
            builder.RegisterType<Checklists>().As<IChecklists>();
            builder.RegisterType<Relationships>().As<IRelationships>();
            builder.RegisterType<ValidStatuses>().As<IValidStatuses>();
            builder.RegisterType<FilterPropertyType>().As<IFilterPropertyType>();
            builder.RegisterType<EventNotesResolver>().As<IEventNotesResolver>();
            builder.RegisterType<EventNotesEmailHelper>().As<IEventNotesEmailHelper>();
            builder.RegisterType<CaseAttributes>().As<ICaseAttributes>();
            builder.RegisterType<ActionEventNotes>().As<IActionEventNotes>();
            builder.RegisterType<FormatDateOfLaw>().As<IFormatDateOfLaw>();
            builder.RegisterType<DesignElements>().As<IDesignElements>();
            builder.RegisterType<FileLocations>().As<IFileLocations>();
            builder.RegisterType<AffectedCases>().As<IAffectedCases>();
            builder.RegisterType<AffectedCasesMaintenance>().As<IAffectedCasesMaintenance>();
        }
    }
}
