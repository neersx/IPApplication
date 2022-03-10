using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Cases
{
    public class CasesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CaseWipCalculator>().As<ICaseWipCalculator>();
            builder.RegisterType<CaseDataCommands>().As<ICaseDataCommands>();
            builder.RegisterType<RestrictedForBilling>().As<IRestrictedForBilling>();
            builder.RegisterType<CaseDataExtension>().As<ICaseDataExtension>();
        }
    }
}