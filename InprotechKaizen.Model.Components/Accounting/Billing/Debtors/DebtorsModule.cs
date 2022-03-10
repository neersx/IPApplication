using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Debtors
{
    public class DebtorsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DebtorListCommands>().As<IDebtorListCommands>();
            builder.RegisterType<DebtorAvailableWipTotals>().As<IDebtorAvailableWipTotals>();
            builder.RegisterType<DebtorRestriction>().As<IDebtorRestriction>();
        }
    }
}