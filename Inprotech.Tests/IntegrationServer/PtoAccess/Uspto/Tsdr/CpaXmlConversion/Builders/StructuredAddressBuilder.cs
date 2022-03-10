using System.Collections.Generic;
using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders
{
    public class StructuredAddressBuilder : IBuilder<XElement>
    {
        public string AddressLineText1 { get; set; }

        public string AddressLineText2 { get; set; }

        public string CityName { get; set; }

        public string GeographicRegionName { get; set; }

        public string PostalCode { get; set; }

        public string CountryCode { get; set; }

        public XElement Build()
        {
            return new XElement(Ns.Common + "PostalAddressBag",
                                new XElement(Ns.Common + "PostalAddress",
                                             new XElement(Ns.Common + "PostalStructuredAddress",
                                                          BuildAddressLines(),
                                                          new XElement(Ns.Common + "CityName", CityName ?? Fixture.String()),
                                                          new XElement(Ns.Common + "GeographicRegionName", GeographicRegionName ?? Fixture.String()),
                                                          new XElement(Ns.Common + "PostalCode", PostalCode ?? Fixture.String()),
                                                          new XElement(Ns.Common + "CountryCode", CountryCode ?? Fixture.String())
                                                         ))
                               );
        }

        IEnumerable<XElement> BuildAddressLines()
        {
            yield return new XElement(Ns.Common + "AddressLineText", AddressLineText1 ?? Fixture.String());

            if (!string.IsNullOrWhiteSpace(AddressLineText2))
            {
                yield return new XElement(Ns.Common + "AddressLineText", AddressLineText2);
            }
        }
    }
}