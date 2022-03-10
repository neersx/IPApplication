using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Search
{
    public class BillSearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BillSearchFilterCriteriaBuilder>().As<IBillSearchFilterCriteriaBuilder>();
        }
    }
   
}
