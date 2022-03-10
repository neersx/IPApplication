using System.Collections.Generic;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Picklists;
using NSubstitute;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using Name = InprotechKaizen.Model.Names.Name;

namespace Inprotech.Tests.Web.Picklists
{
    public class ProfitCentrePicklistControllerFacts : FactBase
    {
       public class ProfitCentreMethod : FactBase
        {
            [Fact]
            public async Task GetFilteredEntity()
            {
                var fixture = new ProfitCentrePicklistControllerFixture(Db);
                var entityOne = new Name
                {
                    FirstName = "first",
                    LastName = "last"
                }.In(Db);

                var entityTwo = new Name
                {
                    FirstName = "test1st",
                    LastName = "testlast"
                }.In(Db);

                new ProfitCentreBuilder { Name = "First", Entity = entityOne }.Build().In(Db);
                new ProfitCentreBuilder { Name = "Second", Entity = entityTwo }.Build().In(Db);
                new ProfitCentreBuilder { Name = "First", Entity = entityOne }.Build().In(Db);
                new ProfitCentreBuilder { Name = "Second", Entity = entityTwo }.Build().In(Db);
                var result = (await fixture.Subject.GetFilterDataForColumn(string.Empty)).ToArray();

                Assert.Equal(2, result.Length);
            }

            [Fact]
            public async Task SearchAndMatchNumberOfRecords()
            {
                var fixture = new ProfitCentrePicklistControllerFixture(Db);

                var entityOne = new Name
                {
                    FirstName = "first",
                    LastName = "last"
                }.In(Db);

                var entityTwo = new Name
                {
                    FirstName = "test1st",
                    LastName = "testlast"
                }.In(Db);

                var first = new ProfitCentreBuilder { Name = "ABC", Entity = entityOne }.Build().In(Db);
                new ProfitCentreBuilder { Name = "pqabcde", Entity = entityTwo }.Build().In(Db);
                new ProfitCentreBuilder { Name = "xyzdef", Entity = entityOne }.Build().In(Db);
                new ProfitCentreBuilder { Name = "QSQDDA", Entity = entityTwo }.Build().In(Db);
                new ProfitCentreBuilder { Name = "abcdef", Entity = entityTwo }.Build().In(Db);
                new ProfitCentreBuilder { Name = "test abc desakin jahb", Entity = entityOne }.Build().In(Db);
                var result = (await fixture.Subject.Search(null, "abc")).Data.ToArray();

                Assert.Equal(4, result.Length);
                Assert.Equal(first.Id, result[0].Code);
                Assert.NotEmpty(result[0].EntityName);
            }

            [Fact]
            public async Task SearchAndVerifyOrder()
            {
                var fixture = new ProfitCentrePicklistControllerFixture(Db);
                var qParams = new CommonQueryParameters { SortBy = "Description", SortDir = "asc", Skip = 0, Take = 10 };

                var third = new ProfitCentreBuilder { Name = "qwl uteslfkin ahetds ABC" }.Build().In(Db);
                var second = new ProfitCentreBuilder { Name = "pqabcde" }.Build().In(Db);
                new ProfitCentreBuilder { Name = "xyzdef" }.Build().In(Db);
                var first = new ProfitCentreBuilder { Name = "abcdef" }.Build().In(Db);
                new ProfitCentreBuilder { Name = "wedikyt kiesdt weslokp akit" }.Build().In(Db);

                var result = (await fixture.Subject.Search(qParams, "abc")).Data.ToArray();

                Assert.Equal(3, result.Length);
                Assert.Equal(first.Id, result[0].Code);
                Assert.Equal(second.Id, result[1].Code);
                Assert.Equal(third.Id, result[2].Code);
            }
            [Fact]
            public async Task SearchWithEmptyResult()
            {
                var fixture = new ProfitCentrePicklistControllerFixture(Db);

                new ProfitCentreBuilder { Name = "AAA" }.Build().In(Db);
                new ProfitCentreBuilder { Name = "BBB" }.Build().In(Db);
                new ProfitCentreBuilder { Name = "CCC" }.Build().In(Db);
                new ProfitCentreBuilder { Name = "DDD" }.Build().In(Db);
                new ProfitCentreBuilder { Name = "EEE" }.Build().In(Db);

                var result = (await fixture.Subject.Search(null, "test")).Data.ToArray();

                Assert.Equal(0, result.Length);
                Assert.Empty(result);
            }

            [Fact]
            public async Task ReturnsPagedResults()
            {
                var fixture = new ProfitCentrePicklistControllerFixture(Db);

                new ProfitCentreBuilder { Name = "AAA" }.Build().In(Db);
                new ProfitCentreBuilder { Name = "CCC" }.Build().In(Db);
                var profitB = new ProfitCentreBuilder { Name = "BBB" }.Build().In(Db);

                var qParams = new CommonQueryParameters { SortBy = "Description", SortDir = "asc", Skip = 1, Take = 1 };
                var result = await fixture.Subject.Search(qParams);
                var profits = result.Data.ToArray();

                Assert.Equal(3, result.Pagination.Total);
                Assert.Single(profits);
                Assert.Equal(profitB.Id, profits.Single().Code);
            }
        }
    }

    public class ProfitCentrePicklistControllerFixture : IFixture<ProfitCentrePicklistController>
    {
        public ProfitCentrePicklistControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            CommonQueryService = Substitute.For<ICommonQueryService>();
            CommonQueryService.Filter(Arg.Any<IEnumerable<ProfitCentrePicklistController.ProfitCentrePicklistItem>>(), Arg.Any<CommonQueryParameters>())
                              .Returns(x => x[0]);
            Subject = new ProfitCentrePicklistController(db, PreferredCultureResolver, CommonQueryService);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }

        public ICommonQueryService CommonQueryService { get; set; }
        public ProfitCentrePicklistController Subject { get; }
    }
}