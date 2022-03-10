using Autofac;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Search.WipOverview;

namespace Inprotech.Web.Search.WipOverview
{
    public class WipOverviewModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<WipOverviewXmlFilterCriteriaBuilder>()
                   .Keyed<IXmlFilterCriteriaBuilder>(QueryContext.WipOverviewSearch);

            builder.RegisterType<CreateBillValidator>().As<ICreateBillValidator>();
        }
    }
}