using Autofac;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;

namespace Inprotech.Web.Configuration.Jurisdictions
{
    public class JurisdictionsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<JurisdictionSearch>().As<IJurisdictionSearch>();
            builder.RegisterType<JurisdictionDetails>().As<IJurisdictionDetails>();
            builder.RegisterType<JurisdictionMaintenance>().As<IJurisdictionMaintenance>();
            builder.RegisterType<GroupMembershipMaintenance>().As<IGroupMembershipMaintenance>();
            builder.RegisterType<OverviewMaintenance>().As<IOverviewMaintenance>();
            builder.RegisterType<TextsMaintenance>().As<ITextsMaintenance>();
            builder.RegisterType<AttributesMaintenance>().As<IAttributesMaintenance>();
            builder.RegisterType<StatusFlagsMaintenance>().As<IStatusFlagsMaintenance>();
            builder.RegisterType<ClassesMaintenance>().As<IClassesMaintenance>();
            builder.RegisterType<StateMaintenance>().As<IStateMaintenance>();
            builder.RegisterType<ValidNumbersMaintenance>().As<IValidNumbersMaintenance>();
            builder.RegisterType<CountryHolidayMaintenance>().As<ICountryHolidayMaintenance>();
        }
    }
}
