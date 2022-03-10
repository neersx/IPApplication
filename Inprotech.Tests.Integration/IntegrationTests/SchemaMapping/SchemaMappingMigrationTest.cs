using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.SchemaMapping.Migration.Models;
using Inprotech.Integration.Storage;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.SchemaMappings;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.SchemaMapping
{
    [TestFixture]
    [Category(Categories.Integration)]
    [RebuildsIntegrationDatabase]
    public class SchemaMappingMigrationTest : IntegrationTest
    {
        [TearDown]
        public void CleanupFiles()
        {
            foreach (var file in _filesAdded)
                FileSetup.DeleteFile(file);
        }

        readonly List<string> _filesAdded = new List<string>();

        void CreateFileInStorage(string file, string name, string fullPath)
        {
            var filePath = FileSetup.SendToStorage(file, name, fullPath.Replace(name, string.Empty));

            _filesAdded.Add(filePath);
        }

        [Test]
        [Ignore("Test is flaky, Investigate on Containerized installation")]
        public void MigrationTests()
        {
            var schemaFiles = new Dictionary<string, Guid>
            {
                {"iponz_patent_application_v1_40.xsd", Guid.NewGuid()},
                {"IPONZ-ISOCountryCodeType-V2006.xsd", Guid.NewGuid()},
                {"IPONZ-WIPOST3CodeType-V2007.xsd", Guid.NewGuid()},
                {"iponz_patent_common_types_v1_40.xsd", Guid.NewGuid()}
            };

            foreach (var schemaFile in schemaFiles)
            {
                IntegrationDbSetup.Do(x => x.Insert(new FileMetadata
                {
                    FileId = schemaFile.Value,
                    Filename = schemaFile.Key,
                    FileGroup = "schemaMapping",
                    ContentHash = Fixture.String(5),
                    FileSize = Fixture.Integer(),
                    SavedOn = DateTime.Today
                }));

                CreateFileInStorage(schemaFile.Key, schemaFile.Value.ToString("N") + ".dat", "schemaMapping");

                IntegrationDbSetup.Do(x => x.Insert(new ObsoleteSchemaFile
                {
                    Name = schemaFile.Key,
                    MetadataId = schemaFile.Value,
                    CreatedOn = DateTime.Today,
                    UpdatedOn = DateTime.Today
                }));
            }

            IntegrationDbSetup.Do(x =>
            {
                var ctx = x.IntegrationDbContext;

                var schemaFile = ctx.Set<ObsoleteSchemaFile>().Single(_ => _.Name == "iponz_patent_application_v1_40.xsd");

                var package = x.Insert(new ObsoleteSchemaPackage
                {
                    Name = schemaFile.Name,
                    CreatedOn = DateTime.Today,
                    UpdatedOn = DateTime.Today,
                    IsValid = true
                });

                schemaFile.IsMappable = true;
                schemaFile.SchemaPackageId = package.Id;

                x.Insert(new ObsoleteSchemaMapping
                {
                    Version = 1,
                    Content = From.EmbeddedAssets("schema-mapping-test-iponz.json"),
                    CreatedOn = DateTime.Today,
                    UpdatedOn = DateTime.Today,
                    Name = schemaFile.Name,
                    SchemaPackageId = package.Id
                });
            });

            var now = DateTime.Now;

            var jobId = IntegrationDbSetup.Do(x =>
            {
                var job = x.IntegrationDbContext.Set<Job>().Single(_ => _.Type == "SchemaPackageMigration");

                job.IsActive = true;

                x.IntegrationDbContext.SaveChanges();

                return job.Id;
            });

            InprotechServer.InterruptJobsScheduler();

            while (DateTime.Now - now < TimeSpan.FromMinutes(5))
            {
                Thread.Sleep(TimeSpan.FromSeconds(10));
                using (var db = new IntegrationDbSetup())
                {
                    var jobExecuted = db.IntegrationDbContext
                                        .Set<JobExecution>()
                                        .OrderByDescending(_ => _.Started)
                                        .FirstOrDefault(_ => _.JobId == jobId);

                    if (jobExecuted?.Finished != null)
                    {
                        break;
                    }
                }
            }

            IntegrationDbSetup.Do(x =>
            {
                Assert.IsEmpty(x.IntegrationDbContext.Set<ObsoleteSchemaFile>(), "Should not have any obsolete schema files in the integration database");

                Assert.IsEmpty(x.IntegrationDbContext.Set<ObsoleteSchemaMapping>(), "Should not have any obsolete mapping files in the integration database");

                Assert.IsEmpty(x.IntegrationDbContext.Set<ObsoleteSchemaPackage>(), "Should not have any obsolete schema package files in the integration database");
            });

            DbSetup.Do(x =>
            {
                var ctx = x.DbContext;

                var schemaPackage = ctx.Set<SchemaPackage>().Single(_ => _.LastModified > now);

                var migratedSchemaFiles = ctx.Set<SchemaFile>().Where(_ => _.SchemaPackageId == schemaPackage.Id).ToArray();

                foreach (var schemaFile in schemaFiles)
                {
                    var migrated = migratedSchemaFiles.SingleOrDefault(_ => _.Name == schemaFile.Key);

                    Assert.NotNull(migrated, $"Should find {schemaFile.Key} in the database");

                    Assert.AreEqual(migrated.Content, From.EmbeddedAssets(schemaFile.Key), $"Should have same content as found in embedded resource for {schemaFile.Key}");
                }

                var schemaMapping = ctx.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>()
                                       .SingleOrDefault(_ => _.Name == "iponz_patent_application_v1_40.xsd");

                Assert.NotNull(schemaMapping, "Should migrate the Mapping");

                var schemaMappingInterfaceToEFiling = ctx.Set<TableCode>()
                                                         .SingleOrDefault(_ => _.Name == "iponz_patent_application_v1_40.xsd"
                                                                               && _.TableTypeId == (short) TableTypes.SchemaMapping);

                Assert.AreEqual(schemaMapping.Id.ToString(), schemaMappingInterfaceToEFiling?.UserCode,
                                $"Should sync user code to {schemaMapping.Id}, but found '{schemaMappingInterfaceToEFiling?.UserCode}' instead.");
            });
        }
    }
}