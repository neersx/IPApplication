using Autofac;
using Inprotech.Integration.Jobs;

namespace Inprotech.Integration.Accounting.Billing
{
    public class BillingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BillProduction>().As<IPerformImmediateBackgroundJob>().AsSelf();
        }
    }
}
