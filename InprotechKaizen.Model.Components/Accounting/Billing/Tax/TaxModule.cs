using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Tax
{
    public class TaxModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<TaxRateResolver>().As<ITaxRateResolver>();
        }
    }
}
