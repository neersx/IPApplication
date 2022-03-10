using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Integration.SchemaMapping.Xsd;
using Inprotech.Tests.Fakes;
using Inprotech.Web.SchemaMapping;
using InprotechKaizen.Model.SchemaMappings;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class SchemaPackageControllerFacts : FactBase
    {
        const string Filename = "filename.xsd";
        const string FileContentText = "file content";

        static JObject BuildUploadMethodParameters(string filename = Filename, string fileContent = FileContentText)
        {
            return JObject.Parse($"{{fileName: \"{filename}\", content:\"{fileContent}\"}}");
        }

        SchemaPackage BuildSchemaPackage(string packageName = "p1", bool isValid = true)
        {
            return new SchemaPackage
            {
                Name = packageName,
                IsValid = isValid
            }.In(Db);
        }

        [Fact]
        public async Task DeleteSchemaFile()
        {
            var schemaPackage = BuildSchemaPackage();
            new SchemaFile
            {
                Id = 1,
                SchemaPackage = schemaPackage
            }.In(Db);

            var schemaInfo = new XsdMetadata(SchemaSetError.None, new string[0]);
            var fixture = new SchemaControllerFixture(Db)
                .WithInspectedSchemaInfo(schemaInfo);

            await fixture.Subject.Delete(schemaPackage.Id, 1);

            Assert.Empty(Db.Set<SchemaFile>());
        }

        [Fact]
        public async Task DeleteSchemaPackageAndItsFiles()
        {
            var schemaPackage = BuildSchemaPackage();
            new SchemaFile
            {
                Id = 1,
                SchemaPackage = schemaPackage
            }.In(Db);
            new SchemaFile
            {
                Id = 2,
                SchemaPackage = schemaPackage
            }.In(Db);
            new SchemaFile
            {
                Id = 3,
                SchemaPackage = schemaPackage
            }.In(Db);

            var fixture = new SchemaControllerFixture(Db);

            await fixture.Subject.Delete(schemaPackage.Id);

            Assert.Empty(Db.Set<SchemaFile>());
        }

        [Fact]
        public async Task GetOrCreateAddsNewPackageIfNotExists()
        {
            var fixture = new SchemaControllerFixture(Db);

            var result = await fixture.Subject.GetOrCreate(-1);

            Assert.Equal("SchemaPackageCreated", result.Status);
            Assert.Equal(1, result.Package.Id);
        }

        [Fact]
        public async Task GetOrCreateReturnsPackageIfExists()
        {
            var schemaPackage = BuildSchemaPackage();
            var newFile = new SchemaFile
            {
                Id = 1,
                SchemaPackage = schemaPackage
            }.In(Db);

            var schemaInfo = new XsdMetadata(SchemaSetError.ValidationError, new[] {"f2"});
            var fixture = new SchemaControllerFixture(Db)
                .WithInspectedSchemaInfo(schemaInfo);

            var result = await fixture.Subject.GetOrCreate(schemaPackage.Id);

            Assert.Equal("SchemaPackageDetails", result.Status);
            Assert.Equal(schemaPackage, result.Package);
            Assert.Equal(1, result.Files.Length);
            Assert.Equal(newFile.Name, result.Files[0].Name);
            Assert.Equal(schemaInfo.SchemaError, result.Error);
            Assert.Equal(schemaInfo.MissingDependencies, result.MissingDependencies);
        }

        [Fact]
        public async Task PackageNameShouldbeUpdated()
        {
            var schemaPackage = BuildSchemaPackage();
            var newName = "newName";
            var parameters = JObject.Parse($"{{name: \"{newName}\"}}");

            var fixture = new SchemaControllerFixture(Db);

            var result = await fixture.Subject.UpdateName(schemaPackage.Id, parameters);

            schemaPackage = Db.Set<SchemaPackage>().Single();

            Assert.Equal("Success", result.Status);
            Assert.Equal(newName, schemaPackage.Name);
        }

        [Fact]
        public async Task PackageNameShouldThrowExceptionForDuplicate()
        {
            var newName = "newName";
            BuildSchemaPackage(newName);
            var schemaPackage = BuildSchemaPackage();

            var parameters = JObject.Parse(string.Format("{{name: \"{0}\"}}", newName));

            var fixture = new SchemaControllerFixture(Db);

            await Assert.ThrowsAsync<HttpResponseException>(() => fixture.Subject.UpdateName(schemaPackage.Id, parameters));
        }

        [Fact]
        public async Task ShouldSyncTableCodesWhenSchemaFileIsDeleted()
        {
            var schemaPackage = BuildSchemaPackage();

            new SchemaFile
            {
                Id = 1,
                SchemaPackage = schemaPackage
            }.In(Db);

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                SchemaPackage = schemaPackage
            }.In(Db);

            var schemaInfo = new XsdMetadata(SchemaSetError.None, new string[0]);
            var fixture = new SchemaControllerFixture(Db)
                .WithInspectedSchemaInfo(schemaInfo);

            await fixture.Subject.Delete(schemaPackage.Id, 1);

            fixture.SyncToTableCodes.Received(1).Sync();
        }

        [Fact]
        public async Task ShouldSyncTableCodesWhenSchemaMappingIsDeleted()
        {
            var fixture = new SchemaControllerFixture(Db);
            var schemaPackage = BuildSchemaPackage();

            new SchemaFile
            {
                Id = 1,
                SchemaPackage = schemaPackage
            }.In(Db);

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                SchemaPackage = schemaPackage
            }.In(Db);

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 2,
                SchemaPackage = schemaPackage
            }.In(Db);

            await fixture.Subject.Delete(schemaPackage.Id);

            fixture.SyncToTableCodes.Received(1);
        }

        [Fact]
        public async Task UploadCreatesSchemaFileIfFileDoesNotExistAndFileIsNotMappable()
        {
            var schemaPackage = BuildSchemaPackage();
            var schemaInfo = new XsdMetadata(SchemaSetError.ValidationError, new[] {"f2"});

            var fixture = new SchemaControllerFixture(Db)
                .WithInspectedSchemaInfo(schemaInfo);

            var parameters = BuildUploadMethodParameters("f1");

            var result = await fixture.Subject.Upload(schemaPackage.Id, parameters);
            var newSchemaFile = fixture.FindCreatedSchemaFile("f1");

            Assert.Equal("SchemaFileCreated", result.Status);
            Assert.Equal(newSchemaFile.Id, result.SchemaFile.Id);
            Assert.Equal(newSchemaFile.Name, result.SchemaFile.Name);
            Assert.Equal(schemaInfo.SchemaError, result.Error);
            Assert.Equal(schemaInfo.MissingDependencies, result.MissingDependencies);
        }

        [Fact]
        public async Task UploadReturnsResultIfFileAlreadyExists()
        {
            var schemaPackage = BuildSchemaPackage();

            var schemaInfo = new XsdMetadata(SchemaSetError.None, new[] {"f3"});

            var fixture = new SchemaControllerFixture(Db)
                .WithInspectedSchemaInfo(schemaInfo);

            var schemaFile = new SchemaFile
            {
                IsMappable = true,
                SchemaPackageId = schemaPackage.Id,
                Name = Filename,
                Content = FileContentText
            }.In(Db);

            var parameters = BuildUploadMethodParameters();
            var result = await fixture.Subject.Upload(schemaPackage.Id, parameters);

            var newFile = Db.Set<SchemaFile>().Last(_ => _.Name == Filename);

            Assert.Equal("FileAlreadyExists", result.Status);
            Assert.Equal(newFile.Id, result.UploadedFileId);
            Assert.Equal(schemaFile.Id, result.ExistingFileId);
        }
    }

    internal class SchemaControllerFixture : IFixture<SchemaPackageController>
    {
        readonly InMemoryDbContext _db;

        public SchemaControllerFixture(InMemoryDbContext db)
        {
            _db = db;
            XsdService = Substitute.For<IXsdService>();

            SyncToTableCodes = Substitute.For<ISyncToTableCodes>();

            Subject = new SchemaPackageController(_db, SyncToTableCodes, Fixture.Today, XsdService);
        }

        public IXsdService XsdService { get; set; }

        public ISyncToTableCodes SyncToTableCodes { get; set; }

        public SchemaPackageController Subject { get; }

        public SchemaFile FindCreatedSchemaFile(string filename)
        {
            return _db.Set<SchemaFile>().SingleOrDefault(_ => _.Name == filename);
        }

        public SchemaControllerFixture WithInspectedSchemaInfo(XsdMetadata xsdMetadata)
        {
            XsdService.Inspect(Arg.Any<int>()).ReturnsForAnyArgs(xsdMetadata);
            return this;
        }
    }
}