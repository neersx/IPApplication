using Autofac;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Search.Name
{
    public class NameModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<NameXmlFilterCriteriaBuilder>()
                   .Keyed<IXmlFilterCriteriaBuilder>(QueryContext.NameSearch)
                   .Keyed<IXmlFilterCriteriaBuilder>(QueryContext.NameSearchExternal);
        }
    }
}