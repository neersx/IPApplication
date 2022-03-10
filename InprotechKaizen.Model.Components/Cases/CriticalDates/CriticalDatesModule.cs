using Autofac;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public class CriticalDatesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<CriticalDatesConfigResolver>().As<ICriticalDatesConfigResolver>();
            builder.RegisterType<CriticalDatesPriorityInfoResolver>().As<ICriticalDatesPriorityInfoResolver>();
            builder.RegisterType<CriticalDatesRenewalInfoResolver>().As<ICriticalDatesRenewalInfoResolver>();
            builder.RegisterType<CriticalDatesMetadataResolver>().As<ICriticalDatesMetadataResolver>();
            
            builder.RegisterType<NumberForEventResolver>().As<INumberForEventResolver>();
            builder.RegisterType<InterimCriticalDatesResolver>().As<IInterimCriticalDatesResolver>();
            builder.RegisterType<InterimLastOccurredDateResolver>().As<IInterimLastOccurredDateResolver>();
            builder.RegisterType<InterimNextDueEventResolver>().As<IInterimNextDueEventResolver>();
            builder.RegisterType<CriticalDatesResolver>().As<ICriticalDatesResolver>();
        }
    }
}