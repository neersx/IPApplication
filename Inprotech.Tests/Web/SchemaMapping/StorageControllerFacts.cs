using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.Storage;
using Inprotech.Tests.Fakes;
using Inprotech.Web.SchemaMapping;
using InprotechKaizen.Model.SchemaMappings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class StorageControllerFacts : FactBase
    {
        readonly IStorage _storage = Substitute.For<IStorage>();

        [Fact]
        public async Task DeleteShouldSucceedWhenFileDoesNotExist()
        {
            var schemaFile = new SchemaFile().In(Db);

            var subject = new StorageController(Db, _storage);

            await subject.Delete(schemaFile.Id);

            Assert.Empty(Db.Set<SchemaFile>());
        }

        [Fact]
        public async Task OverwriteShouldOverwriteTheFileContentAndDeleteOld()
        {
            var existingFile = new SchemaFile
            {
                Content = Fixture.String()
            }.In(Db);

            var newFile = new SchemaFile
            {
                Content = Fixture.String()
            }.In(Db);

            var subject = new StorageController(Db, _storage);

            var result = await subject.Overwrite(existingFile.Id, newFile.Id);

            Assert.Equal(result.UploadedFileId, newFile.Id);
            Assert.True(Db.Set<SchemaFile>().Any(_ => _.Id == newFile.Id));
            Assert.False(Db.Set<SchemaFile>().Any(_ => _.Id == existingFile.Id));
        }
    }
}