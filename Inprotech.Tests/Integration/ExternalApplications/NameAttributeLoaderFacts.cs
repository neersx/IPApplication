using System.Linq;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.Integration.ExternalApplications
{
    public class NameAttributeLoaderFacts
    {
        public class NameAttributeLoaderFixture : IFixture<INameAttributeLoader>
        {
            public NameAttributeLoaderFixture(InMemoryDbContext db)
            {
                DbContext = db;
                Subject = new NameAttributeLoader(DbContext);
            }

            public InMemoryDbContext DbContext { get; set; }

            public INameAttributeLoader Subject { get; }
        }

        public class ListNameAttributeDataMethod : FactBase
        {
            Name _crmName1;
            Name _crmName2;
            TableType _tableTypeCirculars;
            TableType _tableTypeMemberships;
            TableType _tableTypeIndustry;
            TableType _tableTypeOffice;
            TableAttributes _officeTableAttribute;
            Office _office;

            void SetUp()
            {
                _crmName1 = new NameBuilder(Db) {LastName = Fixture.String()}.Build().In(Db);
                _crmName2 = new NameBuilder(Db) {LastName = Fixture.String()}.Build().In(Db);

                _tableTypeIndustry = new TableTypeBuilder(Db) {DatabaseTable = "TABLECODES"}.For(TableTypes.Industry).BuildWithTableCodes().In(Db);
                _tableTypeCirculars = new TableTypeBuilder(Db) {DatabaseTable = "TABLECODES"}.For(TableTypes.Circulars).BuildWithTableCodes().In(Db);
                _tableTypeOffice = new TableTypeBuilder(Db) {DatabaseTable = "OFFICE"}.For(TableTypes.Office).BuildWithTableCodes().In(Db).In(Db);
                _tableTypeMemberships = new TableTypeBuilder(Db) {DatabaseTable = "TABLECODES"}.For(TableTypes.Memberships).BuildWithTableCodes().In(Db);

                TableAttributesBuilder.ForName(_crmName1).WithAttribute(TableTypes.Industry, _tableTypeIndustry.TableCodes.First().Id).Build().In(Db);
                TableAttributesBuilder.ForName(_crmName1).WithAttribute(TableTypes.Circulars, _tableTypeCirculars.TableCodes.First().Id).Build().In(Db);
                TableAttributesBuilder.ForName(_crmName1).WithAttribute(TableTypes.Office, _tableTypeOffice.TableCodes.First().Id).Build().In(Db);

                _officeTableAttribute = TableAttributesBuilder.ForName(_crmName2).WithAttribute(TableTypes.Memberships,
                                                                                                _tableTypeMemberships.TableCodes.First().Id).Build().In(Db);

                _office = new OfficeBuilder {Id = _tableTypeOffice.TableCodes.First().Id}.Build().In(Db);
            }

            [Fact]
            public void ReturnsEmptySelectedAttributesForNotRelevantCrmName()
            {
                SetUp();

                var f = new NameAttributeLoaderFixture(Db);

                var r = f.Subject.ListNameAttributeData(new NameBuilder(Db).Build().In(Db));

                Assert.Empty(r);
            }

            [Fact]
            public void ReturnsOfficeDescriptionForOfficeTableType()
            {
                SetUp();

                var f = new NameAttributeLoaderFixture(Db);

                var r = f.Subject.ListNameAttributeData(_crmName1);

                Assert.Equal(r.First(sa => sa.AttributeTypeId == _tableTypeOffice.Id).AttributeDescription, _office.Name);
            }

            [Fact]
            public void ReturnsSelectedAttributesForRelevantCrmName()
            {
                SetUp();

                var f = new NameAttributeLoaderFixture(Db);

                var r = f.Subject.ListNameAttributeData(_crmName1);

                Assert.True(r.All(sa => sa.AttributeTypeId != _officeTableAttribute.SourceTableId));
            }
        }

        public class ListAttributeTypesMethod : FactBase
        {
            Name _crmName;
            Name _crmLeadName;
            TableType _tableTypeAccountType;

            void SetUp()
            {
                _crmLeadName = new NameBuilder(Db) {LastName = Fixture.String()}.BuildWithClassifications(new[] {KnownNameTypes.Lead}).In(Db);
                _crmName = new NameBuilder(Db) {LastName = Fixture.String()}.BuildWithClassifications(new[] {KnownNameTypes.Contact}).In(Db);

                var tableTypeIndustry = new TableTypeBuilder(Db) {DatabaseTable = "TABLECODES"}.For(TableTypes.Industry).BuildWithTableCodes();
                var tableTypeCirculars = new TableTypeBuilder(Db) {DatabaseTable = "TABLECODES"}.For(TableTypes.Circulars).BuildWithTableCodes().In(Db);
                _tableTypeAccountType = new TableTypeBuilder(Db) {DatabaseTable = "TABLECODES"}.For(TableTypes.AccountType).BuildWithTableCodes().In(Db);

                new SelectionTypesBuilder(Db) {TableType = tableTypeIndustry, ParentTable = KnownParentTable.Lead}.Build().In(Db);
                new SelectionTypesBuilder(Db) {TableType = tableTypeIndustry, ParentTable = KnownParentTable.Individual}.Build().In(Db);
                new SelectionTypesBuilder(Db) {TableType = tableTypeIndustry, ParentTable = KnownParentTable.Employee}.Build().In(Db);
                new SelectionTypesBuilder(Db) {TableType = tableTypeIndustry, ParentTable = KnownParentTable.Organisation}.Build().In(Db);

                new SelectionTypesBuilder(Db) {TableType = tableTypeCirculars, ParentTable = KnownParentTable.Lead}.Build().In(Db);
                new SelectionTypesBuilder(Db) {TableType = tableTypeCirculars, ParentTable = KnownParentTable.Individual}.Build().In(Db);
                new SelectionTypesBuilder(Db) {TableType = tableTypeCirculars, ParentTable = KnownParentTable.Employee}.Build().In(Db);
                new SelectionTypesBuilder(Db) {TableType = tableTypeCirculars, ParentTable = KnownParentTable.Organisation}.Build().In(Db);
            }

            [Fact]
            public void ReturnsBothLeadAndIndividualSelectionTypesForLeadName()
            {
                SetUp();

                new SelectionTypesBuilder(Db) {TableType = _tableTypeAccountType, ParentTable = KnownParentTable.Individual}.Build().In(Db);

                var f = new NameAttributeLoaderFixture(Db);

                var r = f.Subject.ListAttributeTypes(_crmLeadName);

                Assert.True(r.Count(st => st.ParentTable.Contains(KnownParentTable.Lead)) == 2);
                Assert.True(r.Count(st => st.ParentTable.Contains(KnownParentTable.Individual)) == 1);
            }

            [Fact]
            public void ReturnsEmployeeSelectionTypesForNameUsedAsIndvidual()
            {
                SetUp();

                var f = new NameAttributeLoaderFixture(Db);

                _crmName.UsedAs = 1;

                var r = f.Subject.ListAttributeTypes(_crmName);

                Assert.True(r.Count == 2);
                Assert.True(r.All(st => st.ParentTable.Contains(KnownParentTable.Individual)));
            }

            [Fact]
            public void ReturnsEmployeeSelectionTypesForNameUsedAsOrganization()
            {
                SetUp();

                var f = new NameAttributeLoaderFixture(Db);

                _crmName.UsedAs = 4;

                var r = f.Subject.ListAttributeTypes(_crmName);

                Assert.True(r.Count == 2);
                Assert.True(r.All(st => st.ParentTable.Contains(KnownParentTable.Organisation)));
            }

            [Fact]
            public void ReturnsEmployeeSelectionTypesForNameUsedAsStaff()
            {
                SetUp();

                var f = new NameAttributeLoaderFixture(Db);

                _crmName.UsedAs = 2;

                var r = f.Subject.ListAttributeTypes(_crmName);

                Assert.True(r.Count == 2);
                Assert.True(r.All(st => st.ParentTable.Contains(KnownParentTable.Employee)));
            }

            [Fact]
            public void ReturnsOnlyLeadSelectionTypesForLeadName()
            {
                SetUp();

                var f = new NameAttributeLoaderFixture(Db);

                var r = f.Subject.ListAttributeTypes(_crmLeadName);

                Assert.True(r.Count == 2);
                Assert.True(r.All(st => st.ParentTable.Contains(KnownParentTable.Lead)));
            }
        }
    }
}