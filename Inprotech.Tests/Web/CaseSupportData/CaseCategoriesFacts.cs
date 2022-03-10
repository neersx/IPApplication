using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class CaseCategoriesFacts : FactBase
    {
        public CaseCategoriesFacts()
        {
            _fixture = new CaseCategoriesFixture(Db);
        }

        readonly CaseCategoriesFixture _fixture;

        public (CaseCategory caseCategory, ValidCategory validCategory) BuildCategory(
            string key,
            string description,
            string caseType,
            string propertyType,
            string countryKey)
        {
            var caseCategory = new CaseCategory(caseType, key, description + "-base").In(Db);

            var validCategory = new ValidCategory
            {
                CaseCategoryId = key,
                CaseCategoryDesc = description,
                CaseTypeId = caseType,
                PropertyTypeId = propertyType,
                CountryId = countryKey
            }.In(Db);

            return (caseCategory, validCategory);
        }

        [Fact]
        public void ShouldFilterByCaseType()
        {
            BuildCategory("k1", "a", "t1", "p1", "c1");

            BuildCategory("k2", "ab", "t1", "p1", KnownValues.DefaultCountryCode);

            BuildCategory("k3", "abc", "t2", null, null);

            var results = _fixture.Subject.Get(null, "t2", null, null);

            Assert.Equal("k3", results.Single().Key);
        }

        [Fact]
        public void ShouldFilterByCaseTypeCountryAndPropertyType()
        {
            BuildCategory("k1", "a", "t1", "p1", "c1");

            BuildCategory("k2", "ab", "t1", "p1", KnownValues.DefaultCountryCode);

            BuildCategory("k3", "abc", "t2", null, null);

            var results = _fixture.Subject.Get(null, "t1", new[] {"c1"}, new[] {"p1"});

            Assert.Equal("k1", results.Single().Key);
        }

        [Fact]
        public void ShouldFilterByDefaultCountryIfNoResultsFoundBySpecifiedCountry()
        {
            BuildCategory("k1", "a", "t1", "p1", "c1");

            BuildCategory("k2", "ab", "t1", "p1", KnownValues.DefaultCountryCode);

            BuildCategory("k3", "abc", "t2", null, null);

            var results = _fixture.Subject.Get(null, "t1", new[] {"c2"}, new[] {"p1"});

            Assert.Equal("k2", results.Single().Key);
        }

        [Fact]
        public void ShouldFilterByQuery()
        {
            BuildCategory("k1", "a", "t1", "p1", "c1");

            BuildCategory("k2", "ab", "t1", "p1", KnownValues.DefaultCountryCode);

            BuildCategory("k3", "abc", "t2", null, null);

            var results = _fixture.Subject.Get("abc", null, null, null);

            Assert.Single(results);
        }

        [Fact]
        public void ShouldReturnAllByDefault()
        {
            BuildCategory("k1", "a", "t1", "p1", "c1");

            BuildCategory("k2", "ab", "t1", "p1", KnownValues.DefaultCountryCode);

            BuildCategory("k3", "abc", "t2", null, null);

            var results = _fixture.Subject.Get(null, null, null, null);

            Assert.Equal(3, results.Count());
        }

        [Fact]
        public void ShouldReturnBaseCategoryDescriptionWhenNotMatched()
        {
            var vc1 = BuildCategory("k1", "a", "t1", "p1", "c1");

            var vc2 = BuildCategory("k2", "ab", "t1", "p1", KnownValues.DefaultCountryCode);

            BuildCategory("k3", "abc", "t2", null, null);

            var baseCategory = new CaseCategory(vc2.validCategory.CaseTypeId, vc2.validCategory.CaseCategoryId, Fixture.String());

            var @case = new CaseBuilder().Build();
            @case.SetCaseCategory(baseCategory);
            @case.Type = new CaseType(vc1.validCategory.CaseTypeId, Fixture.String());
            @case.Country = new Country(vc1.validCategory.CountryId, Fixture.String());
            @case.PropertyType = new PropertyType(vc1.validCategory.PropertyTypeId, Fixture.String());

            var result = _fixture.Subject.GetCaseCategory(@case);

            Assert.Equal(baseCategory.Name, result);
        }

        [Fact]
        public void ShouldReturnValidCategoryDescriptionWhenMatched()
        {
            var vc1 = BuildCategory("k1", "a", "t1", "p1", "c1");

            BuildCategory("k2", "ab", "t1", "p1", KnownValues.DefaultCountryCode);

            BuildCategory("k3", "abc", "t2", null, null);

            var @case = new CaseBuilder().Build();
            @case.SetCaseCategory(new CaseCategory(vc1.validCategory.CaseTypeId, vc1.validCategory.CaseCategoryId, Fixture.String()));
            @case.Type = new CaseType(vc1.validCategory.CaseTypeId, Fixture.String());
            @case.Country = new Country(vc1.validCategory.CountryId, Fixture.String());
            @case.PropertyType = new PropertyType(vc1.validCategory.PropertyTypeId, Fixture.String());

            var result = _fixture.Subject.GetCaseCategory(@case);

            Assert.Equal(vc1.validCategory.CaseCategoryDesc, result);
        }
    }

    public class CaseCategoriesFixture : IFixture<ICaseCategories>
    {
        public CaseCategoriesFixture(InMemoryDbContext db)
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            preferredCultureResolver.Resolve().Returns("AU");

            Subject = new CaseCategories(db, preferredCultureResolver);
        }

        public ICaseCategories Subject { get; }
    }
}