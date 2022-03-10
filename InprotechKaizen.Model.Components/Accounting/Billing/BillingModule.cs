using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public class BillingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BillingUserPermissionSettingsResolver>().As<IBillingUserPermissionSettingsResolver>();
            builder.RegisterType<BillingSiteSettingsResolver>().As<IBillingSiteSettingsResolver>();
            builder.RegisterType<BillingLanguageResolver>().As<IBillingLanguageResolver>();
            builder.RegisterType<BillSettingsResolver>().As<IBillSettingsResolver>();
            builder.RegisterType<BestNarrativeResolver>().As<IBestNarrativeResolver>();
            builder.RegisterType<TranslatedNarrative>().As<ITranslatedNarrative>();
            builder.RegisterType<BestTranslatedNarrativeResolver>().As<IBestTranslatedNarrativeResolver>();
            builder.RegisterType<ValidateTransactionDates>().As<IValidateTransactionDates>();
            builder.RegisterType<ExchangeDetailsResolver>().As<IExchangeDetailsResolver>();
            builder.RegisterType<GetExchangeDetailsCommand>().As<IGetExchangeDetailsCommand>();
            builder.RegisterType<ElectronicBillingXmlResolver>().As<IElectronicBillingXmlResolver>();
            builder.RegisterType<BillProductionJobDispatcher>().As<IBillProductionJobDispatcher>();
        }
    }
}
