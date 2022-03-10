using System;
using System.Net;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.SchemaMapping;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;
using M = InprotechKaizen.Model;

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class XmlGenCaseApiControllerFacts : FactBase
    {
        const string Xml = @"<?xml version=""1.0"" encoding=""utf-8""?><root></root>";

        XmlGenCaseApiController CreateSubject(string returnError = null)
        {
            var xmlGenService = Substitute.For<IXmlGenService>();
            if (string.IsNullOrWhiteSpace(returnError))
            {
                xmlGenService.Generate(0).ReturnsForAnyArgs(XDocument.Parse(Xml));
            }
            else
            {
                xmlGenService.Generate(0).ThrowsForAnyArgs(new XmlGenException(returnError));
            }

            return new XmlGenCaseApiController(xmlGenService, Db);
        }

        [Fact]
        public async Task ShouldGetErrorForXml()
        {
            const string error = "error";

            var @case = new CaseBuilder().Build().In(Db);
            var schemaMapping = new InprotechKaizen.Model.SchemaMappings.SchemaMapping {Name = "m1"}.In(Db);

            var r = await CreateSubject(error).Get(@case.Id, schemaMapping.Id);
            var obj = r.GetObject();

            Assert.Equal(HttpStatusCode.InternalServerError, r.StatusCode);
            Assert.Equal("FailedToGenerateXml", (string) obj.status);
            Assert.Equal(error, (string) obj.error);
        }

        [Fact]
        public async Task ShouldGetXml()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var schemaMapping = new InprotechKaizen.Model.SchemaMappings.SchemaMapping {Name = "m1"}.In(Db);

            var r = await CreateSubject().Get(@case.Id, schemaMapping.Id);
            var xml = await r.Content.ReadAsStringAsync();

            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal(Xml, xml.Replace(Environment.NewLine, string.Empty));
        }
    }
}