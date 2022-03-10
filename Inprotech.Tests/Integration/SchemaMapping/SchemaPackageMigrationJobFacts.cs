using System.Threading.Tasks;
using Inprotech.Integration.SchemaMapping.Migration;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class SchemaPackageMigrationJobFacts
    {
        [Fact]
        public void GetJobShouldReturnCorrectActivity()
        {
            var fixture = new SchemaPackageMigrationJobFixture();

            var result = fixture.Subject.GetJob(1, null);

            Assert.Equal(typeof(SchemaPackageMigrationJob), result.Type);
            Assert.Equal("Run", result.Name);
        }

        [Fact]
        public async Task RunShouldCallJobHandlerWithJobName()
        {
            var fixture = new SchemaPackageMigrationJobFixture();
            await fixture.Subject.Run(1);

            fixture.SchemaPackageJobHandler.Received(1).Run(fixture.Subject.Type)
                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void TypeShouldBeSchemaPackageMigrationJob()
        {
            Assert.Equal("SchemaPackageMigration", new SchemaPackageMigrationJobFixture().Subject.Type);
        }
    }

    internal sealed class SchemaPackageMigrationJobFixture : IFixture<SchemaPackageMigrationJob>
    {
        public ISchemaPackageJobHandler SchemaPackageJobHandler = Substitute.For<ISchemaPackageJobHandler>();

        public SchemaPackageMigrationJob Subject => new SchemaPackageMigrationJob(SchemaPackageJobHandler);
    }
}