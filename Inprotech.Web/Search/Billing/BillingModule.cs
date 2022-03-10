using Autofac;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Search.Billing
{
    public class BillingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<BillSearchFilterCriteriaBuilder>()
                   .Keyed<IXmlFilterCriteriaBuilder>(QueryContext.BillingSelection);
        }
    }
}
