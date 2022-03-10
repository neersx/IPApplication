using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;
using Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.OPS
{
    public class OpsDataFacts
    {
        public class GetBibliographicDataMethod
        {
            [Fact]
            public void ReturnsCountryAndLanguage()
            {
                var f = new OpsDataFixture();
                var biblioData = new BiblioDataBuilder()
                                 .WithBasicdata("EP", "en", "status")
                                 .Build();

                var docBuilder = new XDocBuilder()
                                 .WithChildElement(biblioData)
                                 .Build();

                var result = f.Subject.GetBibliographicData(docBuilder.ToString());

                Assert.Equal("EP", result.country);
                Assert.Equal("en", result.lang);
            }
        }

        public class GetPatentDataMethod
        {
            [Theory]
            [InlineData("applicationdetails.EP01304846")]
            [InlineData("applicationdetails.EP04779378")]
            public void AccountForNewProceduralStepPhases(string path)
            {
                var f = new OpsDataFixture();
                var rawXml = Tools.ReadFromEmbededResource(TypeNamespace + ".Assets." + path + ".xml");
                Assert.NotNull(f.Subject.GetPatentData(rawXml));
            }

            static string TypeNamespace => typeof(OpsDataFacts).Namespace;

            [Fact]
            public void DeserializesErrorneousTypeLicense()
            {
                var f = new OpsDataFixture();
                var rawXml = Tools.ReadFromEmbededResource(TypeNamespace + ".Assets.applicationdetails.xml");

                var result = f.Subject.GetPatentData(rawXml);

                Assert.NotNull(result);

                Assert.Equal("not exclusive", result.registersearch.registerdocuments[0].registerdocument[0].bibliographicdata.licenseedata[0].licensee[0].typelicense);
            }

            [Fact]
            public void DeserializesPatentData()
            {
                var f = new OpsDataFixture();
                var ns = GetType().Namespace;
                var rawXml = Tools.ReadFromEmbededResource(ns + ".Assets.applicationdetails.v1.xml");

                var result = f.Subject.GetPatentData(rawXml);

                Assert.NotNull(result);
                Assert.Equal("EXAMINATION REQUESTED",
                             result.registersearch.registerdocuments[0].registerdocument[0].bibliographicdata.status);
            }
        }

        class OpsDataFixture : IFixture<OpsData>
        {
            public OpsDataFixture()
            {
                Subject = new OpsData();
            }

            public OpsData Subject { get; }
        }
    }
}