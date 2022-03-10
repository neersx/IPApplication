using System.Xml.Linq;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.SchemaMapping
{
    [TestFixture]
    [Category(Categories.Integration)]
    public class CaseSchemaMappingApiTest : IntegrationTest
    {
        [Test]
        public void UseInCaseWebLink()
        {
            SchemaMappingApiTestData testData;

            using (var integrationDb = new SchemaMappingDbSetup())
            {
                testData = integrationDb.Setup("schema-mapping-api-test.xsd");
            }

            var result = ApiClient.Get<string>($"cases/generate-xml?caseId={testData.CaseId}&mappingId={testData.SchemaMappingId}");

            var response = XElement.Parse(result).ToString(SaveOptions.DisableFormatting);

            var expected = $"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><Case><ref>{testData.CaseRef}</ref></Case>";

            expected = XElement.Parse(expected).ToString(SaveOptions.DisableFormatting);

            Assert.AreEqual(expected, response);
        }
    }
}
