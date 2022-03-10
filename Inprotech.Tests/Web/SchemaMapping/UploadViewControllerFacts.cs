using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.SchemaMapping;
using InprotechKaizen.Model.SchemaMappings;
using Xunit;

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class UploadViewControllerFacts : FactBase
    {
        public UploadViewControllerFacts()
        {
            _controller = new UploadViewController(Db);
        }

        readonly UploadViewController _controller;

        [Fact]
        public async Task ShouldFetchAllSavedMappings()
        {
            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                Name = "m1",
                SchemaPackage = new SchemaPackage
                {
                    Id = 1,
                    Name = "f1"
                }
            }.In(Db);

            new SchemaFile
            {
                Id = 1,
                Name = "f2"
            }.In(Db);

            var r = await _controller.Get();
            var mapping = r.Mappings[0];

            Assert.Equal(1, mapping.Id);
            Assert.Equal("f1", mapping.SchemaPackageName);
            Assert.Equal(1, mapping.SchemaPackageId);
        }

        [Fact]
        public async Task ShouldFetchAllSchemaPackages()
        {
            new SchemaPackage
            {
                Id = 1,
                Name = "f2",
                IsValid = false
            }.In(Db);

            var r = await _controller.Get();

            var schemaPackage = r.SchemaPackages[0];

            Assert.Equal(1, schemaPackage.Id);
            Assert.Equal("f2", schemaPackage.Name);
            Assert.False(schemaPackage.IsValid);
        }
    }
}