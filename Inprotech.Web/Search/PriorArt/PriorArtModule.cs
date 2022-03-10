using Autofac;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Search.PriorArt
{
    public class PriorArtModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PriorArtXmlFilterCriteriaBuilder>()
                   .Keyed<IXmlFilterCriteriaBuilder>(QueryContext.PriorArtSearch);
        }
    }
}