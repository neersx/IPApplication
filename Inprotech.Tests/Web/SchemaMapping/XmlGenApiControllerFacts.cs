using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.SchemaMapping;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class XmlGenApiControllerFacts : FactBase
    {
        public XmlGenApiControllerFacts()
        {
            _bus = Substitute.For<IBus>();
            _xmlGenService = Substitute.For<IXmlGenService>();
            _schemaMappingId = new InprotechKaizen.Model.SchemaMappings.SchemaMapping { Name = "m1" }.In(Db).Id;

            _subject = new XmlGenApiController(_xmlGenService, _bus)
            {
                Request = new HttpRequestMessage(HttpMethod.Get, new Uri($"http://localhost/api/schemappings/{_schemaMappingId}/xmldownload?gstrEntryPoint={EntryPoint}"))
            };
        }

        readonly IBus _bus;
        readonly IXmlGenService _xmlGenService;
        readonly XmlGenApiController _subject;
        readonly int _schemaMappingId;

        const string EntryPoint = "1234/a";

        const string Xml = @"<?xml version=""1.0"" encoding=""utf-8""?><root></root>";

        [Fact]
        public async Task ShouldGetErrorForXml()
        {
            const string error = "error";

            _xmlGenService.Generate(_schemaMappingId)
                          .ThrowsForAnyArgs(new XmlGenException(error));

            var r = await _subject.Get(_schemaMappingId);
            var obj = r.GetObject();

            Assert.Equal(HttpStatusCode.InternalServerError, r.StatusCode);
            Assert.Equal("FailedToGenerateXml", (string) obj.status);
            Assert.Equal(error, (string) obj.error);
        }

        [Fact]
        public async Task ShouldGetXml()
        {
            _xmlGenService.Generate(_schemaMappingId)
                          .ReturnsForAnyArgs(XDocument.Parse(Xml));

            var r = await _subject.Get(_schemaMappingId);
            var xml = await r.Content.ReadAsStringAsync();

            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal(Xml, xml.Replace(Environment.NewLine, string.Empty));
            _bus.Received(1).PublishAsync(Arg.Is<TransactionalAnalyticsMessage>(_ => _.EventType == TransactionalEventTypes.SchemaMappingGeneratedViaApi && _.Value == _schemaMappingId.ToString()));
        }

        [Fact]
        public void RequiresApiKey()
        {
            Assert.True(typeof(XmlGenApiController)
                   .GetCustomAttributes(typeof(RequiresApiKeyAttribute), true)
                   .Cast<RequiresApiKeyAttribute>()
                   .Any(_ => _.ExternalApplicationName == ExternalApplicationName.Inprotech));
        }
    }
}