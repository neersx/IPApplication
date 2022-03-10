using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class NameTypesPicklistControllerFacts : FactBase
    {
        public class NameTypesControllerFixture : IFixture<NameTypesPicklistController>
        {
            readonly InMemoryDbContext _db;

            public NameTypesControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new NameTypesPicklistController(_db, PreferredCultureResolver);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public NameTypesPicklistController Subject { get; }

            public void PrepareData()
            {
                AddNameType("E", "Employee");
                AddNameType(KnownNameTypes.RenewalAgent, "Renewals");
                AddNameType(KnownNameTypes.Agent, "Agent");
                AddNameType("$", "Renewals Agent");
            }

            public void AddStaffNameTypes()
            {
                AddNameType(KnownNameTypes.StaffMember, "Staff Member", 2);
                AddNameType(KnownNameTypes.Paralegal, "Paralegal", 2);
                AddNameType(KnownNameTypes.Signatory, "Signatory", 2);
            }

            void AddNameType(string code, string name, short? picklistFlags = null)
            {
                new NameType(code, name, picklistFlags).In(_db);
            }
        }

        [Fact]
        public void ReturnsAllNameTypesSortedByNameWhenNoFilter()
        {
            var f = new NameTypesControllerFixture(Db);
            f.PrepareData();

            var result = f.Subject.Search(null, null);
            Assert.Equal(4, result.Data.Count());
            Assert.True(((NameTypeModel) result.Data.First()).Value == "Agent");
        }

        [Fact]
        public void ReturnsExactMatchNameType()
        {
            var f = new NameTypesControllerFixture(Db);
            f.PrepareData();

            var result = f.Subject.Search(null, "Agent");
            Assert.Equal(2, result.Data.Count());
            Assert.Contains("Agent", ((NameTypeModel) result.Data.First()).Value);
        }

        [Fact]
        public void ReturnsMatchingNameTypes()
        {
            var f = new NameTypesControllerFixture(Db);
            f.PrepareData();

            var result = f.Subject.Search(null, "Renewals");
            Assert.Equal(2, result.Data.Count());
            Assert.True(((NameTypeModel) result.Data.First()).Value == "Renewals");
            Assert.True(((NameTypeModel) result.Data.Last()).Value == "Renewals Agent");
        }

        [Fact]
        public void ReturnsPagedResults()
        {
            var f = new NameTypesControllerFixture(Db);
            f.PrepareData();

            var qParams = new CommonQueryParameters {Skip = 1, Take = 1};
            var r = f.Subject.Search(qParams, null);

            Assert.Equal(4, r.Pagination.Total);
            Assert.Single(r.Data);
            Assert.True(((NameTypeModel) r.Data.First()).Value == "Employee");
        }

        [Fact]
        public void SortsNameTypesByNameTypeCode()
        {
            var f = new NameTypesControllerFixture(Db);
            f.PrepareData();

            var qParams = new CommonQueryParameters {SortBy = "code", SortDir = "asc"};
            var r = f.Subject.Search(qParams, null);
            var data = (IEnumerable<NameTypeModel>) r.Data;

            Assert.NotNull(data);
            Assert.Equal(4, r.Pagination.Total);
            Assert.Equal(4, r.Data.Count());
            Assert.Equal("$", data.First().Code);
            Assert.Equal("E", data.Last().Code);
        }

        [Fact]
        public void ReturnStaffNameTypesWhenUsedAsStaff()
        {
            var f = new NameTypesControllerFixture(Db);
            f.PrepareData();
            f.AddStaffNameTypes();

            var qParams = new CommonQueryParameters {SortBy = "code", SortDir = "asc"};
            var r = f.Subject.Search(qParams, null, true);
            var data = (IEnumerable<NameTypeModel>) r.Data;

            Assert.Equal(3, r.Data.Count());
            Assert.Equal(KnownNameTypes.StaffMember, data.First().Code);
            Assert.Equal(KnownNameTypes.Signatory, data.Last().Code);
        }
    }
}