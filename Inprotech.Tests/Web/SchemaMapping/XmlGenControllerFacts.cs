using System;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Contracts.Storage;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Inprotech.Tests.Fakes;
using Inprotech.Web.SchemaMapping;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

#pragma warning disable 4014

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class XmlGenControllerFacts : FactBase
    {
        public class GetMethod : FactBase
        {
            public GetMethod()
            {
                var storage = Substitute.For<IStorage>();
                var fileId = Guid.NewGuid();
                var xmlDoc = XDocument.Parse(Xml);

                _xmlGenService = Substitute.For<IXmlGenService>();
                _xmlGenService.Generate(0).ReturnsForAnyArgs(xmlDoc);
                _schemaMappingId = new InprotechKaizen.Model.SchemaMappings.SchemaMapping { Name = "m1" }.In(Db).Id;

                Guid GuidFactory()
                {
                    return fileId;
                }

                _subject = new XmlGenController(_xmlGenService, Db, storage, GuidFactory)
                {
                    Request = new HttpRequestMessage(HttpMethod.Get, new Uri($"http://localhost/api/schemappings/{_schemaMappingId}/xmldownload?gstrEntryPoint={EntryPoint}"))
                };
            }

            readonly IXmlGenService _xmlGenService;
            readonly XmlGenController _subject;
            readonly int _schemaMappingId;

            const string EntryPoint = "1234/a";

            const string Xml = @"<?xml version=""1.0"" encoding=""utf-8""?><root></root>";

            [Fact]
            public async Task ShouldGetErrorForGetXml()
            {
                const string error = "error";

                _xmlGenService.Generate(0).ThrowsForAnyArgs(new XmlGenException(error));

                var r = await _subject.Get(_schemaMappingId);
                var obj = await ((HttpResponseMessage) r).Content.ReadAsAsync<dynamic>();

                Assert.Equal(HttpStatusCode.InternalServerError, r.StatusCode);
                Assert.Equal("FailedToGenerateXml", (string) obj.status);
                Assert.Equal(error, (string) obj.error);
            }

            [Fact]
            public async Task ShouldGetXml()
            {
                var r = await _subject.Get(_schemaMappingId);
                var xml = await r.Content.ReadAsStringAsync();

                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
                Assert.Equal(Xml, xml.Replace(Environment.NewLine, string.Empty));
            }
        }

        public class DownloadMethod : FactBase
        {
            public DownloadMethod()
            {
                Guid GuidFactory()
                {
                    return _fileId;
                }

                _storage = Substitute.For<IStorage>();
                _fileId = Guid.NewGuid();
                _xmlGenService = Substitute.For<IXmlGenService>();
                _xmlGenService.Generate(_schemaMappingId).ReturnsForAnyArgs(XDocument.Parse(Xml));
                
                _schemaMappingId = new InprotechKaizen.Model.SchemaMappings.SchemaMapping { Name = "m1" }.In(Db).Id;

                _subject = new XmlGenController(_xmlGenService, Db, _storage, GuidFactory)
                {
                    Request = new HttpRequestMessage(HttpMethod.Get, new Uri($"http://localhost/api/schemappings/{_schemaMappingId}/xmldownload?gstrEntryPoint={EntryPoint}"))
                };
            }

            readonly IXmlGenService _xmlGenService;
            readonly IStorage _storage;
            readonly Guid _fileId;
            readonly XmlGenController _subject;
            readonly int _schemaMappingId;

            const string EntryPoint = "1234/a";

            const string Xml = @"<?xml version=""1.0"" encoding=""utf-8""?><root></root>";

            [Fact]
            public async Task ShouldGetErrorForDownloadFailed()
            {
                const string error = "error";

                _xmlGenService.Generate(_schemaMappingId).ThrowsForAnyArgs(new XmlGenException(error));

                var r = await _subject.Download(_schemaMappingId);
                var obj = await ((HttpResponseMessage) r).Content.ReadAsAsync<dynamic>();
                
                Assert.Equal(HttpStatusCode.InternalServerError, r.StatusCode);
                Assert.Equal("FailedToGenerateXml", (string) obj.status);
                Assert.Equal(error, (string) obj.error);
            }

            [Fact]
            public async Task ShouldReturnFileIdForDownloadXml()
            {
                var r = await _subject.Download(_schemaMappingId);

                Assert.Equal(_fileId, r);

                _storage.Received(1).SaveText("m1_1234a.xml", Constants.TempFileGroup, _fileId, Arg.Any<string>());
            }
        }

        public class ControllerFacts
        {
            [Fact]
            public void RequiresConfigureSchemaMappingTemplateTask()
            {
                var r = TaskSecurity.Secures<XmlGenController>(ApplicationTask.ConfigureSchemaMappingTemplate);
                Assert.True(r);
            }
        }
    }
}