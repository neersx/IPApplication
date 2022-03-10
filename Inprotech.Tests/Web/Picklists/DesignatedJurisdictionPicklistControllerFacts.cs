using System;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class DesignatedJurisdictionPicklistControllerFacts : FactBase
    {
        [Fact]
        public void ReturnsDesignatedJurisdictionsStartingWithSearchString()
        {
            var pct = new CountryBuilder().Build().In(Db);
            var pctMember = new CountryBuilder {Name = "BBAA"}.Build().In(Db);
            var pctMember1 = new CountryBuilder {Name = "AA"}.Build().In(Db);
            var pctMember2 = new CountryBuilder {Name = "AABB"}.Build().In(Db);
            new CountryGroupBuilder {Id = pct.Id, CountryCode = pctMember.Id, GroupMember = pctMember}.Build().In(Db);
            new CountryGroupBuilder {Id = pct.Id, CountryCode = pctMember1.Id, GroupMember = pctMember1}.Build().In(Db);
            new CountryGroupBuilder {Id = pct.Id, CountryCode = pctMember2.Id, GroupMember = pctMember2}.Build().In(Db);

            var f = new DesignatedJurisdictionPicklistControllerFixture(Db);

            var r = f.Subject.Search(pct.Id, null, "AA").Data.ToArray();

            Assert.Equal(2, r.Length);

            Assert.Equal(pctMember1.Name, r[0].Value);
            Assert.Equal(pctMember2.Name, r[1].Value);
        }

        [Fact]
        public void ReturnsMemberCountriesForGroupProvidedInOrderOfName()
        {
            var pct = new CountryBuilder().Build().In(Db);
            var pctMember = new CountryBuilder {Name = "BBB"}.Build().In(Db);
            var pctMember1 = new CountryBuilder {Name = "AAA"}.Build().In(Db);
            new CountryGroupBuilder {Id = pct.Id, CountryCode = pctMember.Id, GroupMember = pctMember}.Build().In(Db);
            new CountryGroupBuilder {Id = pct.Id, CountryCode = pctMember1.Id, GroupMember = pctMember1}.Build().In(Db);

            var madrid = new CountryBuilder().Build().In(Db);
            var madridMember = new CountryBuilder().Build().In(Db);
            new CountryGroupBuilder {Id = madrid.Id, CountryCode = madridMember.Id}.Build().In(Db);

            var f = new DesignatedJurisdictionPicklistControllerFixture(Db);

            var r = f.Subject.Search(pct.Id).Data.ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal(pctMember1.Name, r[0].Value);
            Assert.Equal(pctMember.Name, r[1].Value);
        }

        [Fact]
        public void ThrowsExceptionIfNoGroupProvided()
        {
            var f = new DesignatedJurisdictionPicklistControllerFixture(Db);
            Assert.Throws<ArgumentNullException>(() => f.Subject.Search(null));
        }
    }

    public class DesignatedJurisdictionPicklistControllerFixture : IFixture<DesignatedJurisdictionsPicklistController>
    {
        public DesignatedJurisdictionPicklistControllerFixture(InMemoryDbContext db)
        {
            var cultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new DesignatedJurisdictionsPicklistController(db, cultureResolver);
        }

        public DesignatedJurisdictionsPicklistController Subject { get; }
    }
}