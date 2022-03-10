using System.Linq;
using System.Xml.Linq;
using Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;
using Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public class CpaXmlConverterFacts
    {
        readonly XNamespace _cpaxmlNs = "http://www.cpasoftwaresolutions.com";

        [Fact]
        public void ConvertsToCpaXml()
        {
            var doc = new XDocBuilder().Build();

            var fixture = new CpaXmlConverterFixture();

            fixture.OpsData.GetPatentData(Arg.Any<string>()).Returns(new WorldPatentFixture().With(doc).WorldPatentData);

            var cpaxmlRaw = fixture.Subject.Convert(doc.ToString());

            var cpaxml = XElement.Parse(cpaxmlRaw);
            var senderDetails = cpaxml.Descendants(_cpaxmlNs + "SenderDetails").Single();
            var caseDetails = cpaxml.Descendants(_cpaxmlNs + "CaseDetails").Single();

            Assert.Equal("EPO", (string) senderDetails.Element(_cpaxmlNs + "Sender"));
            Assert.Equal("Property", (string) caseDetails.Element(_cpaxmlNs + "CaseTypeCode"));
            Assert.Equal("Patent", (string) caseDetails.Element(_cpaxmlNs + "CasePropertyTypeCode"));
            Assert.Equal("EP", (string) caseDetails.Element(_cpaxmlNs + "CaseCountryCode"));
        }
    }

    public class CpaXmlConverterFixture : IFixture<CpaXmlConverter>
    {
        public CpaXmlConverterFixture()
        {
            OfficialNumbersConverter = Substitute.For<IOfficialNumbersConverter>();

            TitlesConverter = Substitute.For<ITitlesConverter>();

            PriorityClaimsConverter = Substitute.For<IPriorityClaimsConverter>();

            NamesConverter = Substitute.For<INamesConverter>();

            ProceduralStepNEventsConverter = Substitute.For<IProceduralStepsAndEventsConverter>();

            OpsData = Substitute.For<IOpsData>();
            var bibliographicData = new bibliographicdata {country = "EP", lang = "en"};
            OpsData.GetBibliographicData(Arg.Any<string>()).Returns(bibliographicData);

            Subject = new CpaXmlConverter(OfficialNumbersConverter, TitlesConverter,
                                          PriorityClaimsConverter, NamesConverter, ProceduralStepNEventsConverter, OpsData);
        }

        public IOfficialNumbersConverter OfficialNumbersConverter { get; set; }

        public ITitlesConverter TitlesConverter { get; set; }

        public IPriorityClaimsConverter PriorityClaimsConverter { get; set; }

        public INamesConverter NamesConverter { get; set; }

        public IProceduralStepsAndEventsConverter ProceduralStepNEventsConverter { get; set; }

        public IOpsData OpsData { get; set; }

        public CpaXmlConverter Subject { get; }
    }
}