using Autofac;
using Inprotech.Web.BatchEventUpdate.DataEntryTaskHandlers;
using Inprotech.Web.BatchEventUpdate.Validators;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using ConfigurationSettings = Inprotech.Infrastructure.ConfigurationSettings;

namespace Inprotech.Web.BatchEventUpdate
{
    public class BatchEventUpdateModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SingleCaseUpdate>().As<ISingleCaseUpdate>();
            builder.RegisterType<BatchEventDataEntryTaskHandler>().AsImplementedInterfaces();
            builder.RegisterType<EventDetailUpdateHandler>().AsImplementedInterfaces();
            builder.RegisterType<EventDetailUpdateValidator>().AsImplementedInterfaces();
            builder.RegisterType<BatchEventsModelBuilder>().AsImplementedInterfaces();
            builder.RegisterType<UpdatableCaseModelBuilder>().AsImplementedInterfaces();
            builder.RegisterType<PrepareAvailableEvents>().As<IPrepareAvailableEvents>();
            builder.RegisterType<WarnOnlyRestrictionsBuilder>().As<IWarnOnlyRestrictionsBuilder>();
            builder.RegisterType<ConfigurationSettings>().AsImplementedInterfaces();
            builder.RegisterType<CaseNamesWithDebtorStatus>().AsImplementedInterfaces();
        }
    }
}