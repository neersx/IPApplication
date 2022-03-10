using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class RelationshipFacts : FactBase
    {
        public RelationshipFacts()
        {
            _defaultCountry = new Country("ZZZ", "Default Country").In(Db);
            _propertyTypePatent = new PropertyType("P", "Patent").In(Db);
        }

        readonly Country _defaultCountry;
        readonly PropertyType _propertyTypePatent;

        [Theory]
        [InlineData("")]
        [InlineData(null)]
        [InlineData("AU")]
        [InlineData("ZZZ")]
        public void FallsBackToDefaultCountry(string countryCode)
        {
            var f = new RelationshipsFixture(Db);
            var r1 = new ValidRelationship(_defaultCountry, _propertyTypePatent, new CaseRelation("r", "relationship 1", null)).In(Db);
            var r2 = new ValidRelationship(_defaultCountry, _propertyTypePatent, new CaseRelation("r2", "relationship 2", null)).In(Db);

            var r = f.Subject.Get(countryCode, "P").ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal(r1.RelationshipCode, r[0].Id);
            Assert.Equal(r1.Relationship.Description, r[0].Description);
            Assert.Equal(r2.RelationshipCode, r[1].Id);
            Assert.Equal(r2.Relationship.Description, r[1].Description);
        }

        [Fact]
        public void GetsValidRelationships()
        {
            var f = new RelationshipsFixture(Db);
            var country = new Country("AU", "Australia");
            var r1 = new ValidRelationship(country, _propertyTypePatent, new CaseRelation("r", "relationship 1", null)).In(Db);
            var r2 = new ValidRelationship(country, _propertyTypePatent, new CaseRelation("r2", "relationship 2", null)).In(Db);
            new ValidRelationship(_defaultCountry, _propertyTypePatent, new CaseRelation("r2", "decoy relationship", null)).In(Db);

            var r = f.Subject.Get("AU", "P").ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal(r1.RelationshipCode, r[0].Id);
            Assert.Equal(r1.Relationship.Description, r[0].Description);
            Assert.Equal(r2.RelationshipCode, r[1].Id);
            Assert.Equal(r2.Relationship.Description, r[1].Description);
        }
    }

    public class RelationshipsFixture : IFixture<Relationships>
    {
        public RelationshipsFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new Relationships(db, PreferredCultureResolver);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public Relationships Subject { get; }
    }
}