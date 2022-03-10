using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.BulkBilling
{
    public class BulkBillingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BillDateSettingsResolver>().As<IBillDateSettingsResolver>();
        }
    }
}
