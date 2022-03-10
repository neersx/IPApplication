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
    public class SubTypesFacts : FactBase
    {
        [Theory]
        [InlineData("", "a", "a", "a")]
        [InlineData("a", "", "a", "a")]
        [InlineData("a", "a", "", "a")]
        [InlineData("a", "a", "a", "")]
        [InlineData("a", "a,b", "a", "a")]
        [InlineData("a", "a", "a,b", "a")]
        [InlineData("a", "a", "a,b", "a,b")]
        public void ShouldReturnAllWhenNotValidSubTypeKey(string caseType, string countries, string propertyTypes, string caseCategories)
        {
            var baseSubTypes = new[]
            {
                new SubType("z", Fixture.String()).In(Db),
                new SubType("y", Fixture.String()).In(Db),
                new SubType("x", Fixture.String()).In(Db)
            };

            var fixture = new SubTypesFixture(Db);

            var results = fixture.Subject.Get(
                                              caseType,
                                              countries.SplitCommaSeparateValues(),
                                              propertyTypes.SplitCommaSeparateValues(),
                                              caseCategories.SplitCommaSeparateValues()).ToArray();

            Assert.Equal(3, results.Length);
            Assert.True(results.All(r => baseSubTypes.Select(s => s.Code).Contains(r.Key)));
        }

        public (SubType subType, ValidSubType validSubType)[] BuildValidSubTypes()
        {
            return new[]
            {
                BuildSubTypeAndValidSubType("k1", "t1", "c1", "p1", "c1", "d1"),
                BuildSubTypeAndValidSubType("k2", "t2", "c2", "p1", "c1", Fixture.String()),
                BuildSubTypeAndValidSubType("k3", "t3", KnownValues.DefaultCountryCode, "p3", "c3", Fixture.String())
            };
        }

        public (SubType subType, ValidSubType validSubType) BuildSubTypeAndValidSubType(string key, string caseType, string country, string propertyType, string caseCategory, string subTypeDescription)
        {
            var subType = new SubType(key, subTypeDescription + "-base").In(Db);

            var validSubType = new ValidSubType(country, propertyType, caseType, caseCategory, key)
            {
                SubTypeDescription = subTypeDescription
            }.In(Db);

            return (subType, validSubType);
        }

        [Fact]
        public void ShouldFilterByCaseTypeCountryPropertyTypeAndCaseCategory()
        {
            BuildValidSubTypes();

            var fixture = new SubTypesFixture(Db);

            var results = fixture.Subject.Get("t1", new[] {"c1"}, new[] {"p1"}, new[] {"c1"});

            Assert.Equal("k1", results.Single().Key);
        }

        [Fact]
        public void ShouldFilterByDefaultCountryIfNoResultsFoundBySpecifiedCountry()
        {
            BuildValidSubTypes();

            var fixture = new SubTypesFixture(Db);

            var results = fixture.Subject.Get("t3", new[] {"c3"}, new[] {"p3"}, new[] {"c3"});

            Assert.Equal("k3", results.Single().Key);
        }

        [Fact]
        public void ShouldReturnBaseSubTypeDescriptionWhenNotMatched()
        {
            var validSubTypes = BuildValidSubTypes();

            var @case = new CaseBuilder().Build();
            @case.SetCaseCategory(new CaseCategory(validSubTypes[0].validSubType.CaseTypeId, validSubTypes[0].validSubType.CaseCategoryId, Fixture.String()));
            @case.SubType = validSubTypes[1].subType;
            @case.Type = new CaseType(validSubTypes[0].validSubType.CaseTypeId, Fixture.String());
            @case.Country = new Country(validSubTypes[0].validSubType.CountryId, Fixture.String());
            @case.PropertyType = new PropertyType(validSubTypes[0].validSubType.PropertyTypeId, Fixture.String());

            var result = new SubTypesFixture(Db).Subject.GetCaseSubType(@case);

            Assert.Equal(validSubTypes[1].subType.Name, result);
        }

        [Fact]
        public void ShouldReturnValidSubTypeDescriptionWhenMatched()
        {
            var validSubTypes = BuildValidSubTypes();

            var @case = new CaseBuilder().Build();
            @case.SetCaseCategory(new CaseCategory(validSubTypes[0].validSubType.CaseTypeId, validSubTypes[0].validSubType.CaseCategoryId, Fixture.String()));
            @case.SubType = validSubTypes[0].subType;
            @case.Type = new CaseType(validSubTypes[0].validSubType.CaseTypeId, Fixture.String());
            @case.Country = new Country(validSubTypes[0].validSubType.CountryId, Fixture.String());
            @case.PropertyType = new PropertyType(validSubTypes[0].validSubType.PropertyTypeId, Fixture.String());

            var result = new SubTypesFixture(Db).Subject.GetCaseSubType(@case);

            Assert.Equal(validSubTypes[0].validSubType.SubTypeDescription, result);
        }
    }

    public class SubTypesFixture : IFixture<ISubTypes>
    {
        public SubTypesFixture(InMemoryDbContext db)
        {
            var cultureResolver = Substitute.For<IPreferredCultureResolver>();
            cultureResolver.Resolve().Returns("AU");

            Subject = new SubTypes(db, cultureResolver);
        }

        public ISubTypes Subject { get; set; }
    }
}