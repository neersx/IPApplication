using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class JurisdictionsPicklistControllerFacts : FactBase
    {
        public class JurisdictionsMethod : FactBase
        {
            [Theory]
            [InlineData("BAR")]
            [InlineData("ABC")]
            public void MarksExactMatch(string searchText)
            {
                var f = new JurisdictionsPicklistControllerFixture(Db);

                var jExact = new CountryBuilder {Id = "BAR", Name = "ABC"}.Build().In(Db);
                new CountryBuilder {Id = "BBC", Name = "BARBRASTREISAND"}.Build().In(Db);
                new CountryBuilder {Id = "BD", Name = "ABCDEFG"}.Build().In(Db);

                var r = f.Subject.Jurisdictions(null, searchText);

                var j = r.Data.OfType<Jurisdiction>().ToArray();

                Assert.Equal(2, j.Length);
                Assert.Equal(jExact.Id, j[0].Code);
            }

            [Fact]
            public void ReturnsJurisdictionsContainingSearchStringOrderedByDescription()
            {
                var f = new JurisdictionsPicklistControllerFixture(Db);

                var j1 = new CountryBuilder {Id = "BAR", Name = "ABCDEFG"}.Build().In(Db);
                var j2 = new CountryBuilder {Id = "BAB", Name = "DEFGHI"}.Build().In(Db);
                var j3 = new CountryBuilder {Id = "BBC", Name = "GHIJKL"}.Build().In(Db);

                new CountryBuilder().Build().In(Db);

                var r = f.Subject.Jurisdictions(null, "AB");

                var j = r.Data.OfType<Jurisdiction>().ToArray();

                Assert.Equal(j1.Id, j[0].Code);
                Assert.Equal(j2.Id, j[1].Code);
                Assert.Null(j.FirstOrDefault(_ => _.Code == j3.Id));
            }

            [Fact]
            public void ReturnsJurisdictionsSortedByDescription()
            {
                var f = new JurisdictionsPicklistControllerFixture(Db);

                var j1 = new CountryBuilder {Id = "B", Name = "AAA"}.Build().In(Db);
                var j2 = new CountryBuilder {Id = "A", Name = "BBB"}.Build().In(Db);
                var j3 = new CountryBuilder {Id = "C", Name = "CCC"}.Build().In(Db);

                var r = f.Subject.Jurisdictions();

                var j = r.Data.OfType<Jurisdiction>().ToArray();

                Assert.Equal(j1.Id, j[0].Code);
                Assert.Equal(j1.Name, j[0].Value);
                Assert.Equal(j2.Id, j[1].Code);
                Assert.Equal(j2.Name, j[1].Value);
                Assert.Equal(j3.Id, j[2].Code);
                Assert.Equal(j3.Name, j[2].Value);
            }

            [Fact]
            public void ReturnsJurisdictionWithMatchingCode()
            {
                var f = new JurisdictionsPicklistControllerFixture(Db);

                var j1 = new CountryBuilder {Id = "B", Name = "AAA"}.Build().In(Db);
                new CountryBuilder {Id = "A", Name = "BBB"}.Build().In(Db);
                new CountryBuilder {Id = "C", Name = "CCC"}.Build().In(Db);

                var r = f.Subject.Jurisdiction(j1.Id);

                Assert.Equal(j1.Id, r.Code);
                Assert.Equal(j1.Name, r.Value);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new JurisdictionsPicklistControllerFixture(Db);

                new CountryBuilder {Id = "ADecoy1"}.Build().In(Db);
                new CountryBuilder {Id = "CDecoy2"}.Build().In(Db);
                var j = new CountryBuilder {Id = "B"}.Build().In(Db);

                var qParams = new CommonQueryParameters {SortBy = "code", SortDir = "asc", Skip = 1, Take = 1};
                var r = f.Subject.Jurisdictions(qParams);
                var jurisdictions = r.Data.OfType<Jurisdiction>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(jurisdictions);
                Assert.Equal(j.Id, jurisdictions.Single().Code);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new JurisdictionsPicklistControllerFixture(Db).Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("Jurisdictions").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("Jurisdiction", picklistAttribute.Name);
            }
        }
    }

    public class JurisdictionsPicklistControllerFixture : IFixture<JurisdictionsPicklistController>
    {
        public JurisdictionsPicklistControllerFixture(InMemoryDbContext db)
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            Subject = new JurisdictionsPicklistController(db, preferredCultureResolver);
        }

        public JurisdictionsPicklistController Subject { get; }
    }
}