using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Integration.SchemaMapping.Xsd;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using Inprotech.Tests.Fakes;
using Inprotech.Web.SchemaMapping;
using InprotechKaizen.Model.SchemaMappings;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

#pragma warning disable 4014

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class MappingViewControllerFacts : FactBase
    {
        [Fact]
        public async Task ShouldForwardCorrectParametersToDocItemReader()
        {
            var id = 1;

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                Name = "test content",
                Content = @"{mappingEntries: {'1': { 'docItem': { 'id': 1 }}}}",
                SchemaPackage = new SchemaPackage().In(Db),
                Version = 1,
                RootNode = $@"{{""name"":""RootNodeName"", ""namespace"":""http://tempuri.org/a"", ""fileName"":""DtDFileName.dtd"" }}"
            }.In(Db);

            var fixture = new MappingViewControllerFixture(Db);

            await fixture.Subject.Get(id);

            fixture.DocItemReader.Received(1).Read(1);
        }

        [Fact]
        public async Task ShouldForwardCorrectParametersToParseXmlSchema()
        {
            var content = "{}";
            var id = 1;
            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = id,
                Content = content,
                SchemaPackage = new SchemaPackage(),
                RootNode = $@"{{""name"":""RootNodeName"", ""namespace"":"""", ""fileName"":""DtDFileName.xsd"" }}"
            }.In(Db);
            var fixture = new MappingViewControllerFixture(Db).WithSchemaPackage();

            await fixture.Subject.Get(id);

            fixture.XsdService.Received(1).Parse(1, Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldReturnCorrectSchemaFileId()
        {
            const string content = "{}";
            var id = 1;

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = id,
                Content = content,
                SchemaPackage = new SchemaPackage(),
                RootNode = $@"{{""name"":""RootNodeName"",  ""namespace"":"""",""fileName"":""DtDFileName.xsd"" }}"
            }.In(Db);

            var fixture = new MappingViewControllerFixture(Db).WithSchemaPackage();

            var result = await fixture.Subject.Get(id);

            Assert.Equal(id, result.Id);
        }

        [Fact]
        public async Task ShouldReturnDocItems()
        {
            var id = 1;

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                Name = "test content",
                Content = @"{mappingEntries: {'a': {'docItem': {'id': 1}}, 'b': {'docItem': {'id': 1}}}}",
                SchemaPackage = new SchemaPackage().In(Db),
                Version = 1,
                RootNode = $@"{{""name"":""RootNodeName"",  ""namespace"":"""",""fileName"":""DtDFileName.xsd"" }}"
            }.In(Db);

            var fixture = new MappingViewControllerFixture(Db);

            var result = await fixture.Subject.Get(id);

            Assert.Equal(1, ((IDictionary<int, object>) result.DocItems).Count);
        }

        [Fact]
        public async Task ShouldReturnFileRefForDtdFiles()
        {
            var id = 1;

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                Name = "test content",
                Content = @"{mappingEntries: {'1': { 'docItem': { 'id': 1 }}}}",
                SchemaPackage = new SchemaPackage().In(Db),
                Version = 1,
                RootNode = $@"{{""name"":""RootNodeName"", ""namespace"":""http://tempuri.org/a"", ""fileName"":""DtDFileName.dtd"", ""fileRef"":""DtDFileName"" }}"
            }.In(Db);

            var fixture = new MappingViewControllerFixture(Db);

            var result = await fixture.Subject.Get(id);

            Assert.Equal(id, result.Id);
            Assert.Equal("RootNodeName", result.RootNodeName);
            Assert.True(result.IsDtdFile);
            Assert.Equal("DtDFileName", result.FileRef);
            Assert.Equal("DtDFileName.dtd", result.FileName);
        }

        [Fact]
        public async Task ShouldReturnMapping()
        {
            var id = 1;
            var name = "test content";

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = id,
                Name = name,
                Content = @"{mappingEntries: {'a': 'b'}}",
                SchemaPackage = new SchemaPackage().In(Db),
                Version = 1,
                RootNode = $@"{{""name"":""RootNodeName"",  ""namespace"":"""",""fileName"":""DtDFileName.xsd"" }}"
            }.In(Db);

            var fixture = new MappingViewControllerFixture(Db);

            var result = await fixture.Subject.Get(id);

            Assert.Equal(JObject.Parse(@"{'a': 'b'}"), result.MappingEntries);
            Assert.Equal(id, result.Id);
            Assert.Equal(name, result.Name);
        }

        [Fact]
        public async Task ShouldReturnMissingDependencies()
        {
            var id = 1;
            var missingDependencies = new[] {"1"};
            var fixture = new MappingViewControllerFixture(Db).WithMissingDependencies(missingDependencies);
            new InprotechKaizen.Model.SchemaMappings.SchemaMapping {Id = id, Name = "n1", SchemaPackage = new SchemaPackage()}.In(Db);

            var r = await fixture.Subject.Get(1);

            Assert.Equal(id, r.Id);
            Assert.Equal("n1", r.Name);
            Assert.Equal(missingDependencies, r.MissingDependencies);
        }

        [Fact]
        public void ShouldThrowNotFoundException()
        {
            var ex = Record.Exception(() => { new MappingViewControllerFixture(Db).Subject.Get(1).Wait(); });

            Assert.IsType<HttpResponseException>(ex.InnerException);

            Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) ex.InnerException).Response.StatusCode);
        }
    }

    public class MappingViewControllerFixture : IFixture<MappingViewController>
    {
        public MappingViewControllerFixture(InMemoryDbContext db)
        {
            XsdService = Substitute.For<IXsdService>();
            XsdService.Parse(Arg.Any<int>(), Arg.Any<string>()).ReturnsForAnyArgs(new XsdTree());

            Repository = db;
            DocItemReader = Substitute.For<IDocItemReader>();
            DocItemReader.Read(0).ReturnsForAnyArgs(new { });
        }

        public IDocItemReader DocItemReader { get; set; }
        public InMemoryDbContext Repository { get; set; }
        public IXsdService XsdService { get; set; }

        public MappingViewController Subject => new MappingViewController(DocItemReader, Repository, XsdService);

        public MappingViewControllerFixture WithSchemaPackage(int id = 1)
        {
            new SchemaPackage
            {
                Id = id,
                Name = "name"
            }.In(Repository);

            return this;
        }

        public MappingViewControllerFixture WithMissingDependencies(string[] missingDependencies)
        {
            XsdService.Parse(Arg.Any<int>(), Arg.Any<string>()).ReturnsForAnyArgs(_ => { throw new MissingSchemaDependencyException(missingDependencies); });

            return this;
        }
    }
}