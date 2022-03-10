using System.Collections.Generic;
using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders
{
    public class GoodsServicesBagBuilder : IBuilder<XElement>
    {
        public GoodsServicesBagBuilder()
        {
            GoodsServices = new List<XElement>();
        }

        public List<XElement> GoodsServices { get; set; }

        public XElement Build()
        {
            return new XElement(Ns.Trademark + "GoodsServicesBag", GoodsServices);
        }
    }
}