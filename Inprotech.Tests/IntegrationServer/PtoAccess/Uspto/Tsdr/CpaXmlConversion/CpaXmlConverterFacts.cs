using System.Linq;
using System.Xml;
using System.Xml.Linq;
using System.Xml.XPath;
using CPAXML;
using Inprotech.Integration.CaseSource;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion;
using Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public class CpaXmlConverterFacts
    {
        readonly XNamespace _cpaxmlNs = "http://www.cpasoftwaresolutions.com";

        public class CpaXmlConverterFixture : IFixture<CpaXmlConverter>
        {
            public CpaXmlConverterFixture()
            {
                TsdrSettings = Substitute.For<ITsdrSettings>();
                TsdrSettings.CommonNs.Returns(Ns.Common);
                TsdrSettings.TrademarkNs.Returns(Ns.Trademark);

                ApplicantsConverter = Substitute.For<IApplicantsConverter>();

                CriticalDatesConverter = Substitute.For<ICriticalDatesConverter>();

                GoodsServicesConverter = Substitute.For<IGoodsServicesConverter>();

                OtherCriticalDetailsConverter = Substitute.For<IOtherCriticalDetailsConverter>();

                EventsConverter = Substitute.For<IEventsConverter>();

                Subject = new CpaXmlConverter(TsdrSettings, ApplicantsConverter, CriticalDatesConverter,
                                              GoodsServicesConverter, OtherCriticalDetailsConverter, EventsConverter);
            }

            public ITsdrSettings TsdrSettings { get; set; }

            public IApplicantsConverter ApplicantsConverter { get; set; }

            public ICriticalDatesConverter CriticalDatesConverter { get; set; }

            public IGoodsServicesConverter GoodsServicesConverter { get; set; }

            public IOtherCriticalDetailsConverter OtherCriticalDetailsConverter { get; set; }

            public IEventsConverter EventsConverter { get; set; }

            public CpaXmlConverter Subject { get; }
        }

        [Fact]
        public void ConvertsToCpaXml()
        {
            var source = new TrademarkBuilder().Build().InTrademarkBag();
            var eligibleCase = new EligibleCase
            {
                CountryCode = "US"
            };
            var fixture = new CpaXmlConverterFixture();
            var cpaxmlRaw = fixture.Subject.Convert(eligibleCase, source.ToString());

            var cpaxml = XElement.Parse(cpaxmlRaw);
            var senderDetails = cpaxml.Descendants(_cpaxmlNs + "SenderDetails").Single();
            var caseDetails = cpaxml.Descendants(_cpaxmlNs + "CaseDetails").Single();

            Assert.Equal("USPTO.TSDR", senderDetails.Element(_cpaxmlNs + "Sender").Value);
            Assert.Equal("Property", caseDetails.Element(_cpaxmlNs + "CaseTypeCode").Value);
            Assert.Equal("Trademark", caseDetails.Element(_cpaxmlNs + "CasePropertyTypeCode").Value);
            Assert.Equal("US", caseDetails.Element(_cpaxmlNs + "CaseCountryCode").Value);

            fixture.ApplicantsConverter.Received(1).Convert(Arg.Any<XPathNavigator>(), Arg.Any<XmlNamespaceManager>(), Arg.Any<CaseDetails>());
            fixture.CriticalDatesConverter.Received(1).Convert(Arg.Any<XPathNavigator>(), Arg.Any<XmlNamespaceManager>(), Arg.Any<CaseDetails>());
            fixture.GoodsServicesConverter.Received(1).Convert(Arg.Any<XPathNavigator>(), Arg.Any<XmlNamespaceManager>(), Arg.Any<CaseDetails>());
            fixture.OtherCriticalDetailsConverter.Received(1).Convert(Arg.Any<XPathNavigator>(), Arg.Any<XmlNamespaceManager>(), Arg.Any<CaseDetails>());
            fixture.EventsConverter.Received(1).Convert(Arg.Any<XPathNavigator>(), Arg.Any<XmlNamespaceManager>(), Arg.Any<CaseDetails>());
        }
    }
}