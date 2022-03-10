using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class NameRelationshipsPicklistControllerFacts : FactBase
    {
        public class NameRelationshipsPicklistControllerFixture : IFixture<NameRelationshipsPicklistController>
        {
            public NameRelationshipsPicklistControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new NameRelationshipsPicklistController(DbContext, PreferredCultureResolver);
            }

            public InMemoryDbContext DbContext { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public NameRelationshipsPicklistController Subject { get; }

            public void PrepareData()
            {
                AddNameRelation("AGT", "Renewal Agent", "Renewal Agent For");
                AddNameRelation("BI2", "Copy Bills To", "Receives Bill Copies For");
                AddNameRelation("EMP", "Employs", "Employee of");
                AddNameRelation("RE2", "Copy Renewals To", "Receives Renewal Copies For");
            }

            void AddNameRelation(string relationship, string relationDescription, string reverseDescription)
            {
                new NameRelation(relationship, relationDescription, reverseDescription, 0, false, 0).In(DbContext);
            }
        }

        [Fact]
        public void ReturnsAllNameRelationshipsSortedByRelationshipDescriptionWhenNoFilter()
        {
            var f = new NameRelationshipsPicklistControllerFixture(Db);
            f.PrepareData();
            var result = f.Subject.Search(null, null);
            Assert.Equal(4, result.Data.Count());
            Assert.True(((NameRelationshipModel) result.Data.First()).RelationDescription == "Copy Bills To");
        }

        [Fact]
        public void ReturnsBestMatchedNameRelationship()
        {
            var f = new NameRelationshipsPicklistControllerFixture(Db);
            f.PrepareData();
            var result = f.Subject.Search(null, "Renewal");
            Assert.Single(result.Data);
            Assert.True(((NameRelationshipModel) result.Data.First()).RelationDescription == "Renewal Agent");
        }

        [Fact]
        public void ReturnsMatchingNameRelationships()
        {
            var f = new NameRelationshipsPicklistControllerFixture(Db);
            f.PrepareData();
            var result = f.Subject.Search(null, "Copy");
            Assert.Equal(2, result.Data.Count());
            Assert.True(((NameRelationshipModel) result.Data.First()).RelationDescription == "Copy Bills To");
        }

        [Fact]
        public void ReturnsPagedResults()
        {
            var f = new NameRelationshipsPicklistControllerFixture(Db);
            f.PrepareData();
            var qParams = new CommonQueryParameters {Skip = 1, Take = 1};
            var r = f.Subject.Search(qParams, null);

            Assert.Equal(4, r.Pagination.Total);
            Assert.Single(r.Data);
            Assert.True(((NameRelationshipModel) r.Data.First()).RelationDescription == "Copy Renewals To");
        }

        [Fact]
        public void SortsNameTypesByReverseDescription()
        {
            var f = new NameRelationshipsPicklistControllerFixture(Db);
            f.PrepareData();
            var qParams = new CommonQueryParameters {SortBy = "reverseDescription", SortDir = "asc"};
            var r = f.Subject.Search(qParams, null);
            var data = (IEnumerable<NameRelationshipModel>) r.Data;

            Assert.NotNull(data);
            Assert.Equal(4, r.Pagination.Total);
            Assert.Equal(4, r.Data.Count());
            Assert.Equal("Employee of", data.First().ReverseDescription);
            Assert.Equal("Renewal Agent For", data.Last().ReverseDescription);
        }
    }
}