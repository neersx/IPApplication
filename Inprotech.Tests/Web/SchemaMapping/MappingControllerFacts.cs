using System.Linq;
using System.Threading.Tasks;
using System.Xml.Schema;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Tests.Fakes;
using Inprotech.Web.SchemaMapping;
using InprotechKaizen.Model.SchemaMappings;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class MappingControllerFacts : FactBase
    {
        public class DeleteMapping : FactBase
        {
            [Fact]
            public async Task ShouldDeleteSchemaMappingInDatabase()
            {
                var schemaPackage = new SchemaPackage
                {
                    Id = 1,
                    Name = "schema file"
                }.In(Db);
                new InprotechKaizen.Model.SchemaMappings.SchemaMapping
                {
                    Id = 1,
                    Name = "test mapping",
                    SchemaPackage = schemaPackage
                }.In(Db);

                var fixture = new MappingControllerFixture(Db);

                await fixture.Subject.Delete(1);

                var mapping = Db.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().SingleOrDefault(m => m.Id == 1);
                var schema = Db.Set<SchemaPackage>().SingleOrDefault(m => m.Id == 1);

                Assert.Null(mapping);
                Assert.NotNull(schema);
            }

            [Fact]
            public async Task ShouldPublishMappingNameChangedEvent()
            {
                var data = JObject.Parse(@"{mappings: {a: 'b'}, name: 'newName', isDtdFile: false}");
                var fixture = new MappingControllerFixture(Db);

                new InprotechKaizen.Model.SchemaMappings.SchemaMapping {RootNode = @"{name: 'RootNodeName', namespace: '', fileName: 'DtDFileName.xsd'}"}.In(Db);

                await fixture.Subject.Put(1, data);

                fixture.SyncToTableCodes.Received(1).Sync();
            }

            [Fact]
            public async Task ShouldSyncTableCodesOnDelete()
            {
                var fixture = new MappingControllerFixture(Db);
                var schemaPackage = new SchemaPackage().In(Db);
                var mapping = new InprotechKaizen.Model.SchemaMappings.SchemaMapping
                {
                    SchemaPackage = schemaPackage
                }.In(Db);

                await fixture.Subject.Delete(mapping.Id);

                fixture.SyncToTableCodes.Received(1).Sync();
            }

            [Fact]
            public async Task ShouldUpdateExistingMappingInDatabase()
            {
                var data = JObject.Parse(@"{mappings: {a: 'b'}, name: 'newName', isDtdFile: false}");

                new InprotechKaizen.Model.SchemaMappings.SchemaMapping
                {
                    Id = 1,
                    Content = "{}",
                    Name = string.Empty,
                    Version = Constants.MappingVersion,
                    RootNode = @"{name: 'RootNodeName', namespace: '', fileName: 'DtDFileName.xsd'}"
                }.In(Db);

                var fixture = new MappingControllerFixture(Db);

                await fixture.Subject.Put(1, data);

                var result = Db.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().Single(m => m.Id == 1);

                Assert.Equal(data["mappings"].ToString(), result.Content);
            }

            [Fact]
            public async Task ShouldUpdateFileRef()
            {
                var data = JObject.Parse(@"{mappings: {a: 'b'}, name: 'newName', isDtdFile: true, fileRef: 'abcd'}");

                var fixture = new MappingControllerFixture(Db);

                new InprotechKaizen.Model.SchemaMappings.SchemaMapping {RootNode = @"{name: 'RootNodeName', namespace: '', fileName: 'DtDFileName.dtd'}"}.In(Db);

                await fixture.Subject.Put(1, data);

                var savedMapping = Db.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().Single(_ => _.Id == 1);
                var rootNodeInfo = new RootNodeInfo().ParseJson(savedMapping.RootNode);
                Assert.Equal("abcd", rootNodeInfo.FileRef);
            }

            [Fact]
            public async Task ShouldUpdateMappingName()
            {
                var data = JObject.Parse(@"{mappings: {a: 'b'}, name: 'newName', isDtdFile: false}");

                var fixture = new MappingControllerFixture(Db);

                var m = new InprotechKaizen.Model.SchemaMappings.SchemaMapping {RootNode = @"{name: 'RootNodeName', namespace: '', fileName: 'DtDFileName.xsd'}"}.In(Db);

                await fixture.Subject.Put(1, data);

                Assert.Equal("newName", m.Name);
            }
        }

        public class AddMapping : FactBase
        {
            static JObject GetInput(string mappingName = "", int schemaPackageId = 1, int? copyMappingFrom = null, string rootNode = "")
            {
                return new JObject
                {
                    {"mappingName", mappingName},
                    {"schemaPackageId", schemaPackageId},
                    {"copyMappingFrom", copyMappingFrom},
                    {"rootNode", rootNode}
                };
            }

            [Fact]
            public async Task CheckMappingNameIsProvided()
            {
                var fixture = new MappingControllerFixture(Db);
                var result = await fixture.Subject.Post(GetInput());

                Assert.Equal("NameError", result.Status);
                Assert.Equal("MandatoryName", result.Error);
            }

            [Fact]
            public async Task CheckMappingNameIsUnique()
            {
                new InprotechKaizen.Model.SchemaMappings.SchemaMapping {Name = "Abcd"}.In(Db);

                var fixture = new MappingControllerFixture(Db);
                var result = await fixture.Subject.Post(GetInput("Abcd"));

                Assert.Equal("NameError", result.Status);
                Assert.Equal("DuplicateName", result.Error);
            }

            [Fact]
            public async Task NewMappingDataIsReturned()
            {
                var node = new RootNodeInfo {FileName = "File.xsd", Node = new XmlSchemaElement()};
                var schema = new SchemaPackage {Id = 1, Name = "schemaPackage", IsValid = true}.In(Db);
                new SchemaFile {Id = 1, SchemaPackageId = schema.Id, Name = node.FileName}.In(Db);

                var fixture = new MappingControllerFixture(Db);
                var result = await fixture.Subject.Post(GetInput("newMapping", schema.Id, null, node.ToJsonString()));

                Assert.Equal("MappingCreated", result.Status);
                Assert.Equal("newMapping", result.Mapping.Name);
                Assert.Equal(1, result.Mapping.SchemaPackageId);
                Assert.Equal("schemaPackage", result.Mapping.SchemaPackageName);
            }

            [Fact]
            public async Task NewMappingIsCopiedFromExisting()
            {
                var node = new RootNodeInfo {FileName = "File.xsd", Node = new XmlSchemaElement()};
                var package = new SchemaPackage {Id = 1, Name = "schemaPackage", IsValid = true}.In(Db);
                new SchemaFile {Id = 1, SchemaPackageId = package.Id, Name = node.FileName}.In(Db);
                var existingMapping = new InprotechKaizen.Model.SchemaMappings.SchemaMapping {Id = 99, Name = "existingMapping", Content = "someContent", SchemaPackage = package}.In(Db);

                var fixture = new MappingControllerFixture(Db);
                await fixture.Subject.Post(GetInput("newMapping", 1, 99, node.ToJsonString()));

                var newMapping = Db.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().Single(_ => _.Id == 1);

                Assert.NotNull(newMapping);
                Assert.Equal(existingMapping.Content, newMapping.Content);
            }

            [Fact]
            public async Task NewMappingIsCreatedAndTableCodesSynced()
            {
                var node = new RootNodeInfo {FileName = "File.xsd", Node = new XmlSchemaElement()};
                var schema = new SchemaPackage {Id = 1, Name = "schemaPackageFile", IsValid = true}.In(Db);
                new SchemaFile {Id = 1, SchemaPackageId = schema.Id, Name = node.FileName}.In(Db);

                var fixture = new MappingControllerFixture(Db);
                await fixture.Subject.Post(GetInput("newMapping", 1, null, node.ToJsonString()));

                var newMapping = Db.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().SingleOrDefault();

                Assert.NotNull(newMapping);
                Assert.Equal(1, newMapping.Version);
                Assert.Equal("newMapping", newMapping.Name);
                Assert.Equal(1, newMapping.SchemaPackageId);
                Assert.Null(newMapping.Content);

                fixture.SyncToTableCodes.Received(1).Sync();
            }
        }
    }

    public class MappingControllerFixture : IFixture<MappingController>
    {
        public MappingControllerFixture(InMemoryDbContext db)
        {
            SyncToTableCodes = Substitute.For<ISyncToTableCodes>();

            Subject = new MappingController(db, SyncToTableCodes);
        }

        public ISyncToTableCodes SyncToTableCodes { get; set; }

        public MappingController Subject { get; }
    }
}