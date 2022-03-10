using System;
using System.IO;
using System.Net;
using System.Web;
using System.Xml.Linq;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.ApplicationLinkApi
{

    [TestFixture]
    [Category(Categories.Integration)]
    [RebuildsIntegrationDatabase]
    public class SchemaMappingViaApi : IntegrationTest
    {
        [Test]
        public void EFilingIntegration()
        {
            SchemaMappingApiTestData testData;

            using (var integrationDb = new SchemaMappingDbSetup())
            {
                testData = integrationDb.Setup("schema-mapping-api-test.xsd");
            }

            var uri = new Uri(Env.RootUrl + $"/api/schemamappings/{testData.SchemaMappingId}/xml?gstrEntryPoint={HttpUtility.UrlEncode(testData.CaseRef)}");

            var client = new WebClient { Headers = { ["X-ApiKey"] = testData.ApiKey } };

            var expected = $"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><Case><ref>{testData.CaseRef}</ref></Case>";

            expected = XElement.Parse(expected).ToString(SaveOptions.DisableFormatting);

            string response;
            try
            {
                response = client.DownloadString(uri);
                response = XElement.Parse(response).ToString(SaveOptions.DisableFormatting);
            }
            catch (Exception e)
            {
                var web = e as WebException;
                if (web != null && web.Status == WebExceptionStatus.ProtocolError)
                {
                    using (var respStream = new StreamReader(web.Response.GetResponseStream()))
                        response = respStream.ReadToEnd();
                }
                else
                {
                    response = e.Message;
                }
            }

            Assert.AreEqual(expected, response);
        }

        [Test]
        public void EFilingIntegrationDtd()
        {
            SchemaMappingApiTestData testData;
            var fileName = "schema-mapping-e2e-test.dtd";
            using (var integrationDb = new SchemaMappingDbSetup())
            {
                testData = integrationDb.SetupDtd(fileName);
            }

            var uri = new Uri(Env.RootUrl + $"/api/schemamappings/{testData.SchemaMappingId}/xml");

            var client = new WebClient { Headers = { ["X-ApiKey"] = testData.ApiKey } };

            var expected = $"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\r\n<!DOCTYPE rootNode SYSTEM \"{fileName}\">\r\n<rootNode lang=\"en\" produced-by=\"applicant\">\r\n  <document-id>1</document-id><invention-title id=\"ID1\" lang=\"en\" />  <ep-declarations><empty-element /><name>e2e</name></ep-declarations>\r\n</rootNode>";

            expected = XElement.Parse(expected).ToString(SaveOptions.DisableFormatting);

            string responseRaw = string.Empty, response;
            try
            {
                responseRaw = client.DownloadString(uri);
                response = XElement.Parse(responseRaw).ToString(SaveOptions.DisableFormatting);
            }
            catch (Exception e)
            {
                var web = e as WebException;
                if (web != null && web.Status == WebExceptionStatus.ProtocolError)
                {
                    using (var respStream = new StreamReader(web.Response.GetResponseStream()))
                        response = respStream.ReadToEnd();
                }
                else
                {
                    response = e.Message;
                }
            }

            Assert.True(responseRaw.Contains($"<!DOCTYPE rootNode SYSTEM \"{fileName}\">"));
            Assert.AreEqual(expected, response);
        }

        [Test]
        public void EFilingIntegrationDtdWithValidationErrors()
        {
            SchemaMappingApiTestData testData;
            var fileName = "schema-mapping-e2e-test.dtd";
            using (var integrationDb = new SchemaMappingDbSetup())
            {
                testData = integrationDb.SetupDtd(fileName, false);
            }

            var uri = new Uri(Env.RootUrl + $"/api/schemamappings/{testData.SchemaMappingId}/xml");

            var client = new WebClient { Headers = { ["X-ApiKey"] = testData.ApiKey } };

            var expected = $"<!DOCTYPE rootNode SYSTEM \"schema-mapping-e2e-test.dtd\">\r\n<rootNode lang=\"en\" xmlns=\"http://tempuri.org/a\" />";

            JObject responseObject = null;
            try
            {
                 client.DownloadString(uri);
            }
            catch (Exception e)
            {
                var web = e as WebException;
                if (web != null && web.Status == WebExceptionStatus.ProtocolError)
                {
                    using (var respStream = new StreamReader(web.Response.GetResponseStream()))
                    {
                        var response = respStream.ReadToEnd();
                        responseObject = JObject.Parse(response);
                    }
                }
            }

            Assert.AreEqual("FailedToGenerateXml", responseObject?["status"].Value<string>());
            Assert.AreEqual(expected, responseObject?["xml"].Value<string>());
            var error = responseObject?["error"].Value<string>() ?? string.Empty;
            Assert.True(error.Contains("Xml validation failed"));
            Assert.True(error.Contains("The required attribute 'produced-by' is missing."));
            Assert.True(error.Contains("The element 'rootNode' in namespace 'http://tempuri.org/a' has incomplete content. List of possible elements expected: 'document-id, doc-page' in namespace 'http://tempuri.org/a'"));
        }
    }
}
