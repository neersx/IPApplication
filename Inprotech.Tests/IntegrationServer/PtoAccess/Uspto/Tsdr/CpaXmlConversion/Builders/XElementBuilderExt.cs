using System.Collections.Generic;
using System.Xml.Linq;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders
{
    public static class XElementBuilderExt
    {
        public static XElement AsTsdrSource(this XElement source)
        {
            return new XElement(Ns.Trademark + "TrademarkBag",
                                new XElement(Ns.Trademark + "Trademark",
                                             source
                                            )
                               );
        }

        public static XElement AsTsdrSource(this IEnumerable<XElement> source)
        {
            return new XElement(Ns.Trademark + "TrademarkBag",
                                new XElement(Ns.Trademark + "Trademark",
                                             source
                                            )
                               );
        }

        public static XElement InTrademarkBag(this XElement source)
        {
            return new XElement(Ns.Trademark + "TrademarkBag", source);
        }
    }
}