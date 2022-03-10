using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.BulkCaseImport;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.BulkCaseImport.NameResolution;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport.NameResolution
{
    public class NameMapperFacts
    {
        public class NameMapperFixture : IFixture<INameMapper>
        {
            public NameMapperFixture(InMemoryDbContext db)
            {
                DbContext = db;
                SetupBatch();
                MapName = new NameBuilder(DbContext).Build().In(db);

                Subject = new NameMapper(DbContext);
            }

            public InMemoryDbContext DbContext { get; }
            public NameAlias NameAlias { get; private set; }
            public EdeSenderDetails SenderDetails { get; private set; }
            public EdeUnresolvedName UnresolvedName { get; private set; }
            public Name MapName { get; }
            public INameMapper Subject { get; }

            public NameMapperFixture WithNameAlias()
            {
                NameAlias = new NameAliasBuilder(DbContext)
                            {
                                AliasType = new NameAliasType {Code = KnownAliasTypes.EdeIdentifier}
                            }
                            .WithNoCountry()
                            .WithNoPropertyType()
                            .Build().In(DbContext);

                SenderDetails.Sender = NameAlias.Alias;

                return this;
            }

            public NameMapperFixture WithUnmappedImportedNames()
            {
                new EdeAddressBook
                {
                    BatchId = SenderDetails.TransactionHeader.BatchId,
                    NameId = null,
                    UnresolvedNameId = UnresolvedName.Id
                }.In(DbContext);

                return this;
            }

            void SetupBatch()
            {
                var edeBuilder = new EdeBatchBuilder(DbContext, 1, "ABC", EdeBatchStatus.Unprocessed);
                var batch = edeBuilder.Build();
                SenderDetails = edeBuilder.EdeSenderDetails;

                UnresolvedName = new EdeUnresolvedNameBuilder
                {
                    BatchId = batch.BatchId
                }.Build().In(DbContext);
            }
        }

        public class MapFacts : FactBase
        {
            [Fact]
            public void DeletesTheUnresolvedName()
            {
                var f = new NameMapperFixture(Db).WithNameAlias();

                f.Subject.Map(f.SenderDetails.TransactionHeader.BatchId, f.UnresolvedName.Id, f.MapName.Id);

                var unresolvedName =
                    f.DbContext.Set<EdeUnresolvedName>().FirstOrDefault(n => n.Id == f.UnresolvedName.Id);

                Assert.Null(unresolvedName);
            }

            [Fact]
            public void MapsNameInBatch()
            {
                var f = new NameMapperFixture(Db)
                        .WithNameAlias()
                        .WithUnmappedImportedNames();

                f.Subject.Map(f.SenderDetails.TransactionHeader.BatchId, f.UnresolvedName.Id, f.MapName.Id);

                var importedName = f.DbContext.Set<EdeAddressBook>().FirstOrDefault();

                Assert.NotNull(importedName);
                Assert.Null(importedName.UnresolvedNameId);
                Assert.Equal(f.MapName.Id, importedName.NameId);
            }

            [Fact]
            public void SavesAndMapsExternalName()
            {
                var f = new NameMapperFixture(Db).WithNameAlias();

                f.Subject.Map(f.SenderDetails.TransactionHeader.BatchId, f.UnresolvedName.Id, f.MapName.Id);

                var extName = f.DbContext.Set<ExternalName>().FirstOrDefault();

                Assert.NotNull(extName);
                Assert.Equal(f.NameAlias.Name.Id, extName.DataSourceNameId);
                Assert.Equal(f.UnresolvedName.Email, extName.Email);
                Assert.Equal(f.UnresolvedName.EntityType, extName.EntityType);
                Assert.Equal(f.UnresolvedName.SenderNameIdentifier, extName.ExternalNameCode);
                Assert.Equal(f.UnresolvedName.Name, extName.ExtName);
                Assert.Equal(f.UnresolvedName.FirstName, extName.FirstName);
                Assert.Equal(f.UnresolvedName.NameType, extName.NameType);
                Assert.Equal(f.UnresolvedName.Fax, extName.Fax);
                Assert.Equal(f.UnresolvedName.Phone, extName.Phone);

                var extAddress = extName.ExternalNameAddress;

                Assert.Equal(f.UnresolvedName.AddressLine, extAddress.Address);
                Assert.Equal(f.UnresolvedName.City, extAddress.City);
                Assert.Equal(f.UnresolvedName.State, extAddress.State);
                Assert.Equal(f.UnresolvedName.PostCode, extAddress.PostCode);
                Assert.Equal(f.UnresolvedName.CountryCode, extAddress.Country);

                var extNameMap = f.DbContext.Set<ExternalNameMapping>().FirstOrDefault();

                Assert.NotNull(extNameMap);
                Assert.Equal(extName.Id, extNameMap.ExternalNameId);
                Assert.Equal(f.MapName.Id, extNameMap.InproNameId);
            }
        }
    }
}