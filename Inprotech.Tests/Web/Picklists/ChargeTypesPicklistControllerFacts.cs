using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Accounting;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ChargeTypesPicklistControllerFacts : FactBase
    {
        public class ChargeTypesMethod : FactBase
        {
            [Fact]
            public void MarksExactMatch()
            {
                var f = new ChargeTypesPicklistControllerFixture(Db);

                var ctExact = new ChargeType {Id = Fixture.Integer(), Description = "ABC"}.In(Db);
                new ChargeType {Id = Fixture.Integer(), Description = "BARBRASTREISAND"}.In(Db);
                new ChargeType {Id = Fixture.Integer(), Description = "ABCDEFG"}.In(Db);

                var r = f.Subject.Search(null, "ABC");

                var ct = r.Data.ToArray();

                Assert.Equal(2, ct.Length);
                Assert.Equal("ABC", ct[0].Value);
                Assert.Equal("ABCDEFG", ct[1].Value);
            }

            [Fact]
            public void ReturnsChargeTypesContainingSearchStringOrderedByDescription()
            {
                var f = new ChargeTypesPicklistControllerFixture(Db);

                var ct1 = new ChargeType {Id = Fixture.Integer(), Description = "GRAB"}.In(Db);
                var ct2 = new ChargeType {Id = Fixture.Integer(), Description = "ABCDEFG"}.In(Db);
                var ct3 = new ChargeType {Id = Fixture.Integer(), Description = "GHIJKL"}.In(Db);

                var r = f.Subject.Search(null, "AB");

                var ct = r.Data.OfType<ChargeTypesPicklistController.ChargeTypeListItem>().ToArray();

                Assert.Equal(ct1.Id, ct[1].Key);
                Assert.Equal(ct2.Id, ct[0].Key);
                Assert.Null(ct.FirstOrDefault(_ => _.Key == ct3.Id));
            }

            [Fact]
            public void ReturnsChargeTypesSortedByDescription()
            {
                var f = new ChargeTypesPicklistControllerFixture(Db);

                var ct1 = new ChargeType {Id = Fixture.Integer(), Description = "AAA"}.In(Db);
                var ct2 = new ChargeType {Id = Fixture.Integer(), Description = "BBB"}.In(Db);
                var ct3 = new ChargeType {Id = Fixture.Integer(), Description = "CCC"}.In(Db);

                var r = f.Subject.Search();

                var ct = r.Data.OfType<ChargeTypesPicklistController.ChargeTypeListItem>().ToArray();

                Assert.Equal(ct1.Id, ct[0].Key);
                Assert.Equal(ct1.Description, ct[0].Value);
                Assert.Equal(ct2.Id, ct[1].Key);
                Assert.Equal(ct2.Description, ct[1].Value);
                Assert.Equal(ct3.Id, ct[2].Key);
                Assert.Equal(ct3.Description, ct[2].Value);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new ChargeTypesPicklistControllerFixture(Db);

                new ChargeType {Id = Fixture.Integer(), Description = "A"}.In(Db);
                var ct = new ChargeType {Id = Fixture.Integer(), Description = "B"}.In(Db);
                new ChargeType {Id = Fixture.Integer(), Description = "C"}.In(Db);

                var qParams = new CommonQueryParameters {SortBy = "Value", SortDir = "asc", Skip = 1, Take = 1};
                var r = f.Subject.Search(qParams);
                var ChargeTypes = r.Data.OfType<ChargeTypesPicklistController.ChargeTypeListItem>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(ChargeTypes);
                Assert.Equal(ct.Id, ChargeTypes.Single().Key);
            }
        }
    }

    public class ChargeTypesPicklistControllerFixture : IFixture<ChargeTypesPicklistController>
    {
        public ChargeTypesPicklistControllerFixture(InMemoryDbContext db)
        {
            var cultureResolver = Substitute.For<IPreferredCultureResolver>();

            Subject = new ChargeTypesPicklistController(db, cultureResolver);
        }

        public ChargeTypesPicklistController Subject { get; }
    }
}