using System;
using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders
{
    public class TrademarkBuilder : IBuilder<XElement>
    {
        public DateTime? ApplicationDate { get; set; }

        public string ApplicationNumber { get; set; }

        public DateTime? RegistrationDate { get; set; }

        public string RegistrationNumber { get; set; }

        public DateTime? PublicationDate { get; set; }

        public DateTime? AbandonDate { get; set; }

        public string DisclaimerText { get; set; }

        public string MarkDescription { get; set; }

        public string MarkVerbalElement { get; set; }

        public string StatusCode { get; set; }

        public string StatusDescription { get; set; }

        public DateTime? StatusDate { get; set; }

        public XElement Build()
        {
            return new XElement(Ns.Trademark + "Trademark",
                                new XElement(Ns.Common + "ApplicationNumber",
                                             new XElement(Ns.Common + "ApplicationNumberText", ApplicationNumber ?? Fixture.String())),
                                new XElement(Ns.Trademark + "ApplicationDate", ApplicationDate ?? Fixture.Today()),
                                new XElement(Ns.Common + "RegistrationNumber", RegistrationNumber ?? Fixture.String()),
                                new XElement(Ns.Common + "RegistrationDate", RegistrationDate ?? Fixture.Today()),
                                new XElement(Ns.Trademark + "NationalTrademarkInformation",
                                             new XElement(Ns.Trademark + "ApplicationAbandonedDate", AbandonDate ?? Fixture.Today())),
                                new XElement(Ns.Trademark + "PublicationBag",
                                             new XElement(Ns.Trademark + "Publication",
                                                          new XElement(Ns.Common + "PublicationDate", PublicationDate ?? Fixture.Today()))),
                                new XElement(Ns.Trademark + "MarkDisclaimerBag",
                                             new XElement(Ns.Trademark + "MarkDisclaimerText", DisclaimerText ?? Fixture.String())),
                                new XElement(Ns.Trademark + "MarkRepresentation",
                                             new XElement(Ns.Trademark + "MarkDescriptionBag",
                                                          new XElement(Ns.Trademark + "MarkDescriptionText", MarkDescription ?? Fixture.String())),
                                             new XElement(Ns.Trademark + "MarkReproduction",
                                                          new XElement(Ns.Trademark + "WordMarkSpecification",
                                                                       new XElement(Ns.Trademark + "MarkVerbalElementText", MarkVerbalElement ?? Fixture.String())))),
                                new XElement(Ns.Trademark + "MarkCurrentStatusCode", StatusCode ?? Fixture.String()),
                                new XElement(Ns.Trademark + "MarkCurrentStatusDate", StatusDate ?? Fixture.Today()),
                                new XElement(Ns.Trademark + "NationalTrademarkInformation",
                                             new XElement(Ns.Trademark + "MarkCurrentStatusExternalDescriptionText", StatusDescription ?? Fixture.String()))
                               );
        }
    }
}