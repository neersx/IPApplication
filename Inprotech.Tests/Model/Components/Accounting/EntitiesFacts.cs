using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Common;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting
{
    public class EntitiesFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public async Task FallsBackToHomeNameIfStaffOfficeOrgNameNotAnEntity()
            {
                var staffId = Fixture.Integer();
                var f = new EntitiesFixture(Db);
                var fakeOfficeEntity = new Office {OrganisationId = f.NonEntity.Id, Id = Fixture.Integer()}.In(Db);
                new Employee {Id = staffId}.In(Db);
                new TableAttributesBuilder {GenericKey = staffId.ToString(), ParentTable = KnownTableAttributes.Name, TableTypeId = (short) TableTypes.Office, TableCodeId = fakeOfficeEntity.Id}.Build().In(Db);
                var result = await f.Subject.Get(staffId);
                var entityNames = result as EntityName[] ?? result.ToArray();
                Assert.Equal(2, entityNames.Length);
                Assert.Equal(f.HomeName.Id, entityNames.First().Id);
                Assert.Equal(f.OtherName.Id, entityNames.Last().Id);
                Assert.True(entityNames.First().IsDefault);
                Assert.False(entityNames.Last().IsDefault);
            }

            [Fact]
            public async Task MarksStaffOfficeOrgNameAsDefault()
            {
                var staffId = Fixture.Integer();
                var f = new EntitiesFixture(Db, true);
                new Employee {Id = staffId}.In(Db);
                new TableAttributesBuilder {GenericKey = staffId.ToString(), ParentTable = KnownTableAttributes.Name, TableTypeId = (short) TableTypes.Office, TableCodeId = f.Office.Id}.Build().In(Db);
                var result = await f.Subject.Get(staffId);
                var entityNames = result as EntityName[] ?? result.ToArray();
                Assert.Equal(2, entityNames.Length);
                Assert.Equal(f.HomeName.Id, entityNames.First().Id);
                Assert.Equal(f.OtherName.Id, entityNames.Last().Id);
                Assert.False(entityNames.First().IsDefault);
                Assert.True(entityNames.Last().IsDefault);
            }

            [Fact]
            public async Task DefaultsToHomeNameIfStaffHasMultipleOffices()
            {
                var staffId = Fixture.Integer();
                var f = new EntitiesFixture(Db, true);
                new Employee {Id = staffId}.In(Db);
                var fakeOfficeEntity = new Office {OrganisationId = f.OtherName.Id, Id = Fixture.Integer()}.In(Db);
                new TableAttributesBuilder {GenericKey = staffId.ToString(), ParentTable = KnownTableAttributes.Name, TableTypeId = (short) TableTypes.Office, TableCodeId = f.Office.Id}.Build().In(Db);
                new TableAttributesBuilder {GenericKey = staffId.ToString(), ParentTable = KnownTableAttributes.Name, TableTypeId = (short) TableTypes.Office, TableCodeId = fakeOfficeEntity.Id}.Build().In(Db);
                var result = await f.Subject.Get(staffId);
                var entityNames = result as EntityName[] ?? result.ToArray();
                Assert.Equal(2, entityNames.Length);
                Assert.Equal(f.HomeName.Id, entityNames.First().Id);
                Assert.Equal(f.OtherName.Id, entityNames.Last().Id);
                Assert.True(entityNames.First().IsDefault);
                Assert.False(entityNames.Last().IsDefault);
            }

            [Fact]
            public async Task MarksStaffWipEntityAsDefault()
            {
                var staffId = Fixture.Integer();
                var f = new EntitiesFixture(Db);
                new Employee {Id = staffId, DefaultEntityId = f.OtherName.Id}.In(Db);
                var result = await f.Subject.Get(staffId);
                var entityNames = result as EntityName[] ?? result.ToArray();
                Assert.Equal(2, entityNames.Length);
                Assert.Equal(f.HomeName.Id, entityNames.First().Id);
                Assert.Equal(f.OtherName.Id, entityNames.Last().Id);
                Assert.False(entityNames.First().IsDefault);
                Assert.True(entityNames.Last().IsDefault);
            }

            [Fact]
            public async Task ReturnsAllEntitiesInNameOrder()
            {
                var staffId = Fixture.Integer();
                new Employee {Id = staffId}.In(Db);
                var f = new EntitiesFixture(Db);
                var result = await f.Subject.Get(staffId);
                var entityNames = result as EntityName[] ?? result.ToArray();
                Assert.Equal(2, entityNames.Length);
                Assert.Equal(f.HomeName.Id, entityNames.First().Id);
                Assert.Equal(f.OtherName.Id, entityNames.Last().Id);
                Assert.True(entityNames.First().IsDefault);
                Assert.False(entityNames.Last().IsDefault);
            }
        }

        public class IsRestrictedByCurrencyMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnFalseIfSiteEntityNotToBeRestrictedByCurrency()
            {
                var f = new EntitiesFixture(Db);

                f.SiteControlReader.Read<bool>(SiteControls.EntityRestrictionByCurrency)
                 .Returns(false);

                var r = await f.Subject.IsRestrictedByCurrency(f.HomeName.Id);

                Assert.False(r);
            }

            [Fact]
            public async Task ShouldReturnFalseIfCurrencyUnset()
            {
                var f = new EntitiesFixture(Db);

                f.SiteControlReader.Read<bool>(SiteControls.EntityRestrictionByCurrency)
                 .Returns(true);

                f.SiteControlReader.Read<string>(SiteControls.CURRENCY)
                 .Returns("USD");

                var entity = Db.Set<SpecialName>().Single(_ => _.Id == f.HomeName.Id);
                entity.Currency = null;
                entity.IsEntity = 1;

                var r = await f.Subject.IsRestrictedByCurrency(f.HomeName.Id);

                Assert.False(r);
            }

            [Fact]
            public async Task ShouldReturnFalseIfNotAnEntity()
            {
                var f = new EntitiesFixture(Db);

                f.SiteControlReader.Read<bool>(SiteControls.EntityRestrictionByCurrency)
                 .Returns(true);

                f.SiteControlReader.Read<string>(SiteControls.CURRENCY)
                 .Returns("USD");

                var entity = Db.Set<SpecialName>().Single(_ => _.Id == f.HomeName.Id);
                entity.Currency = "ABC";
                entity.IsEntity = null;

                var r = await f.Subject.IsRestrictedByCurrency(f.HomeName.Id);

                Assert.False(r);
            }

            [Fact]
            public async Task ShouldReturnFalseIfCurrencyIsSameAsLocalCurrency()
            {
                var f = new EntitiesFixture(Db);

                f.SiteControlReader.Read<bool>(SiteControls.EntityRestrictionByCurrency)
                 .Returns(true);

                f.SiteControlReader.Read<string>(SiteControls.CURRENCY)
                 .Returns("USD");

                var entity = Db.Set<SpecialName>().Single(_ => _.Id == f.HomeName.Id);
                entity.Currency = "USD";
                entity.IsEntity = 1;

                var r = await f.Subject.IsRestrictedByCurrency(f.HomeName.Id);

                Assert.False(r);
            }

            [Fact]
            public async Task ShouldReturnTrueIfCurrencyIsNotSameAsLocalCurrency()
            {
                var f = new EntitiesFixture(Db);

                f.SiteControlReader.Read<bool>(SiteControls.EntityRestrictionByCurrency)
                 .Returns(true);

                f.SiteControlReader.Read<string>(SiteControls.CURRENCY)
                 .Returns("USD");

                var entity = Db.Set<SpecialName>().Single(_ => _.Id == f.HomeName.Id);
                entity.Currency = "ABC";
                entity.IsEntity = 1;

                var r = await f.Subject.IsRestrictedByCurrency(f.HomeName.Id);

                Assert.True(r);
            }
        }
        
        public class EntitiesFixture : IFixture<Entities>
        {
            public EntitiesFixture(InMemoryDbContext db, bool withOfficeAttribute = false)
            {
                HomeName = new NameBuilder(db) {LastName = "AAA"}.Build().In(db);
                OtherName = new NameBuilder(db) {LastName = "ZZZ"}.Build().In(db);
                new SpecialName(true, HomeName).In(db);
                new SpecialName(true, OtherName).In(db);
                NonEntity = new SpecialNameBuilder(db) {EntityFlag = false}.Build();

                new SiteControlBuilder {SiteControlId = SiteControls.HomeNameNo, IntegerValue = HomeName.Id}.Build().In(db);
                SiteControlReader = Substitute.For<ISiteControlReader>();
                SiteControlReader.Read<int>(SiteControls.HomeNameNo).Returns(HomeName.Id);
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
                DisplayFormattedName.For(Arg.Any<int[]>())
                                    .Returns(x =>
                                    {
                                        var names = db.Set<Name>();

                                        return ((int[]) x[0]).ToDictionary(k => k,
                                                                           v => new NameFormatted
                                                                           {
                                                                               NameId = v,
                                                                               Name = names.SingleOrDefault(_ => _.Id == v)?.LastName
                                                                           });
                                    });
                Subject = new Entities(db, SiteControlReader, DisplayFormattedName);

                if (!withOfficeAttribute) return;
                Office = new Office {OrganisationId = OtherName.Id, Id = Fixture.Integer()}.In(db);
            }

            public Office Office { get; }
            public Name HomeName { get; }
            public Name OtherName { get; }
            public SpecialName NonEntity { get; }
            public ISiteControlReader SiteControlReader { get; }
            public IDisplayFormattedName DisplayFormattedName { get; }
            public Entities Subject { get; }
        }
    }
}