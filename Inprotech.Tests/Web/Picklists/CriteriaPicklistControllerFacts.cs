using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Tests.Web.Configuration.Rules;
using Inprotech.Web.Picklists;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class CriteriaPicklistControllerFacts
    {
        public class TypeaheadSearchMethod : FactBase
        {
            static readonly CommonQueryParameters QueryParameters = new CommonQueryParameters {Skip = 0, SortBy = "Id", SortDir = "asc", Take = 10};

            [Fact]
            public void OrdersById()
            {
                var f = new CriteriaPicklistControllerFixture(Db);
                new CriteriaBuilder {Id = Fixture.Integer()}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = Fixture.Integer()}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = Fixture.Integer()}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.TypeaheadSearch(string.Empty, QueryParameters, "E");

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(3, results.Count());
                Assert.True(results[0].Id < results[1].Id);
                Assert.True(results[1].Id < results[2].Id);
            }

            [Fact]
            public void ReturnsAllRules()
            {
                var f = new CriteriaPicklistControllerFixture(Db);
                var protectedCriteria = new CriteriaBuilder {Id = -123}.ForEventsEntriesRule().Build().In(Db);
                var regularCriteria = new CriteriaBuilder {Id = 0}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.TypeaheadSearch(string.Empty, QueryParameters, "E");

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(2, results.Length);
                Assert.NotNull(results.SingleOrDefault(r => r.Id == regularCriteria.Id));
                Assert.NotNull(results.SingleOrDefault(r => r.Id == protectedCriteria.Id));
            }

            [Fact]
            public void ReturnsExactMatchOnIdFirst()
            {
                var f = new CriteriaPicklistControllerFixture(Db);
                var criteriaById =
                    new CriteriaBuilder {Id = 1, Description = "Desc"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = -11, Description = "DescA"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = -12, Description = "DescB"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = -13, Description = "DescC"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = -14, Description = "DescD"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = -15, Description = "DescE"}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.TypeaheadSearch("1", new CommonQueryParameters(), "E");

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(6, results.Count());
                Assert.Equal(criteriaById.Id, results.First().Id);
            }

            [Fact]
            public void ReturnsExactMatchOnIdFirstThenWhereIdStartsWith()
            {
                var f = new CriteriaPicklistControllerFixture(Db);
                var match1 = new CriteriaBuilder {Id = 160, Description = "DescC"}.ForEventsEntriesRule().Build().In(Db);
                var match2 = new CriteriaBuilder {Id = 1600, Description = "Desc"}.ForEventsEntriesRule().Build().In(Db);
                var match3 = new CriteriaBuilder {Id = 1601, Description = "Desc"}.ForEventsEntriesRule().Build().In(Db);
                var match4 = new CriteriaBuilder {Id = 3160, Description = "DescA"}.ForEventsEntriesRule().Build().In(Db);
                var match5 = new CriteriaBuilder {Id = -160, Description = "DescB"}.ForEventsEntriesRule().Build().In(Db);
                var match6 = new CriteriaBuilder {Id = 2, Description = "Desc160"}.ForEventsEntriesRule().Build().In(Db);
                var match7 = new CriteriaBuilder {Id = 1, Description = "Desc2"}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.TypeaheadSearch("160", new CommonQueryParameters(), "E");

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(6, results.Count());
                Assert.Equal(match1.Id, results[0].Id);
                Assert.Equal(match2.Id, results[1].Id);
                Assert.Equal(match3.Id, results[2].Id);
                Assert.Equal(match4.Id, results[3].Id);
                Assert.Equal(match5.Id, results[4].Id);
                Assert.Equal(match6.Id, results[5].Id);
            }
            
            [Fact]
            public void TakesTake()
            {
                var f = new CriteriaPicklistControllerFixture(Db);
                for (var i = 0; i <= 15; i++) new CriteriaBuilder {Id = Fixture.Integer()}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.TypeaheadSearch(string.Empty, QueryParameters, "E");
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(10, results.Count());
            }

            [Fact]
            public void ReturnsOnlyExpectedPurposeCode()
            {
                var f = new CriteriaPicklistControllerFixture(Db);
                for (var i = 0; i < 5; i++) new CriteriaBuilder {Id = Fixture.Integer()}.ForEventsEntriesRule().Build().In(Db);
                for (var i = 0; i < 3; i++) new CriteriaBuilder {Id = Fixture.Integer()}.ForWindowControl().Build().In(Db);

                var result = f.Subject.TypeaheadSearch(string.Empty, QueryParameters, "E");
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(5, results.Count());
            }

            [Fact]
            public void WhereIdOrDescriptionContainsQuery()
            {
                var f = new CriteriaPicklistControllerFixture(Db);
                var criteriaById =
                    new CriteriaBuilder {Id = 12678912, Description = "Desc"}.ForEventsEntriesRule().Build().In(Db);
                var criteriaByDesc =
                    new CriteriaBuilder {Id = 888, Description = "Six Was Sad Cos 789 Ten"}.ForEventsEntriesRule()
                                                                                           .Build()
                                                                                           .In(Db);

                var result = f.Subject.TypeaheadSearch("789", QueryParameters, "E");

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(2, results.Count());
                var r1 = results.SingleOrDefault(r => r.Id == criteriaById.Id);
                var r2 = results.SingleOrDefault(r => r.Description == criteriaByDesc.Description);
                Assert.NotNull(r1);
                Assert.NotNull(r2);
                Assert.Equal(criteriaById.Description, r1.Description);
                Assert.Equal(criteriaByDesc.Id, r2.Id);
            }
        }
        public class CriteriaPicklistControllerFixture : IFixture<CriteriaPicklistController>
        {
            public CriteriaPicklistControllerFixture(InMemoryDbContext db)
            {
                Subject = new CriteriaPicklistController(db);
            }
            public CriteriaPicklistController Subject { get; }
        }
    }
}
