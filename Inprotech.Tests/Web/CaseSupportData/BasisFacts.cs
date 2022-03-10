using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class BasisFacts : FactBase
    {
        [Fact]
        public void DoesNotReturnDuplicates()
        {
            var basisKey = Fixture.String();
            var basisDesc = Fixture.String();

            new ApplicationBasis(basisKey, basisDesc).In(Db);

            new ApplicationBasis(basisKey, basisDesc).In(Db);

            new ApplicationBasis(basisKey, basisDesc).In(Db);

            var fixture = new BasisFixture(Db);

            var results = fixture.Subject.Get(null, null, null, null).ToArray();

            Assert.Equal(basisKey, results.Single().Key);
        }

        [Fact]
        public void FallsBackToValidBasisWhenNoValidBasisEx()
        {
            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "A"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "B"
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = "B",
                PropertyTypeId = "propertyType",
                CountryId = "country",
                CaseTypeId = "caseType",
                CaseCategoryId = "otherCaseCategory"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "C"
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = "C",
                PropertyTypeId = "propertyType",
                CountryId = "country",
                CaseTypeId = "caseType",
                CaseCategoryId = "otherCaseCategory1"
            }.In(Db);

            var fixture = new BasisFixture(Db);

            var results = fixture.Subject.Get("caseType", new[] {"country"}, new[] {"propertyType"}, new[] {"caseCategory"})
                                 .ToArray();

            Assert.Contains(results, _ => _.Key == "A");
            Assert.Contains(results, _ => _.Key == "B");
            Assert.Contains(results, _ => _.Key == "C");
        }

        [Fact]
        public void IgnoresCaseTypeAndCategoryFromValidBasisExWhenCaseCategoryNotPassed()
        {
            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "A"
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = "A",
                PropertyTypeId = "propertyType",
                CountryId = "country",
                CaseTypeId = "caseType",
                CaseCategoryId = "caseCategory"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "B"
            }.In(Db);

            var fixture = new BasisFixture(Db);

            var result = fixture.Subject.Get(string.Empty, new[] {"country"}, new[] {"propertyType"}, null).ToArray();

            Assert.Contains(result, _ => _.Key == "A");
            Assert.Contains(result, _ => _.Key == "B");
        }

        [Fact]
        public void ReturnsOnlyValidBasisExWhenMatched()
        {
            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "A"
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = "A",
                PropertyTypeId = "propertyType",
                CountryId = "country",
                CaseTypeId = "caseType",
                CaseCategoryId = "caseCategory"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "B"
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = "B",
                PropertyTypeId = "propertyType",
                CountryId = "country",
                CaseTypeId = "caseType",
                CaseCategoryId = "otherCaseCategory"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "B"
            }.In(Db);

            var fixture = new BasisFixture(Db);

            var results = fixture.Subject.Get("caseType", new[] {"country"}, new[] {"propertyType"}, new[] {"caseCategory"})
                                 .ToArray();

            Assert.Single(results, r => r.Key == "A");
        }

        [Fact]
        public void ReturnValidBasisExWithDefaultCountryWhenNoValidBasisOrValidBasisEx()
        {
            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = KnownValues.DefaultCountryCode,
                BasisId = "A"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "B"
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = "B",
                PropertyTypeId = "propertyType",
                CountryId = "country",
                CaseTypeId = "caseType",
                CaseCategoryId = "otherCaseCategory"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "C"
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = "C",
                PropertyTypeId = "propertyType",
                CountryId = "country",
                CaseTypeId = "caseType",
                CaseCategoryId = "otherCaseCategory1"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = KnownValues.DefaultCountryCode,
                BasisId = "D"
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = "D",
                PropertyTypeId = "propertyType",
                CountryId = KnownValues.DefaultCountryCode,
                CaseTypeId = "caseType",
                CaseCategoryId = "caseCategory"
            }.In(Db);

            var fixture = new BasisFixture(Db);

            var results = fixture.Subject.Get("caseType", new[] {"otherCountry"}, new[] {"propertyType"}, new[] {"caseCategory"})
                                 .ToArray();

            Assert.Single(results);
            Assert.Single(results, r => r.Key == "D");
        }

        [Fact]
        public void ReturnValidBasisWithDefaultCountryWhenNoValidBasisOrValidBasisExOrValidBasisExWithDefault()
        {
            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "D"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = KnownValues.DefaultCountryCode,
                BasisId = "A"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "B"
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = "B",
                PropertyTypeId = "propertyType",
                CountryId = "country",
                CaseTypeId = "caseType",
                CaseCategoryId = "caseCategory"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = "C"
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = "C",
                PropertyTypeId = "propertyType",
                CountryId = "country",
                CaseTypeId = "caseType",
                CaseCategoryId = "caseCategory"
            }.In(Db);

            var fixture = new BasisFixture(Db);

            var results = fixture.Subject.Get("caseType", new[] {"otherCountry"}, new[] {"propertyType"}, new[] {"caseCategory"})
                                 .ToArray();

            Assert.Single(results);
            Assert.Single(results, r => r.Key == "A");
        }

        [Fact]
        public void ShouldReturnItemsWithMatchingCaseTypePropertyTypeCaseCategoryCountryKey()
        {
            var matchingItemKey = Fixture.String();
            var matchingItemDescription = Fixture.String();

            new ValidBasis
            {
                PropertyTypeId = "propertyType",
                CountryId = "country",
                BasisId = matchingItemKey,
                BasisDescription = matchingItemDescription
            }.In(Db);

            new ValidBasisEx
            {
                BasisId = matchingItemKey,
                PropertyTypeId = "propertyType",
                CountryId = "country",
                CaseTypeId = "caseType",
                CaseCategoryId = "caseCategory"
            }.In(Db);

            new ValidBasis
            {
                PropertyTypeId = "non-matching",
                CountryId = "non-matching",
                BasisId = Fixture.String(),
                BasisDescription = Fixture.String()
            }.In(Db);

            var fixture = new BasisFixture(Db);

            var result = fixture.Subject.Get("caseType", new[] {"country"}, new[] {"propertyType"}, new[] {"caseCategory"})
                                .Single();

            Assert.Equal(matchingItemKey, result.Key);
            Assert.Equal(matchingItemDescription, result.Value);
        }
    }

    public class BasisFixture : IFixture<IBasis>
    {
        public BasisFixture(InMemoryDbContext db)
        {
            var cultureResolver = Substitute.For<IPreferredCultureResolver>();
            cultureResolver.Resolve().Returns("AU");

            Subject = new Basis(db, cultureResolver);
        }

        public IBasis Subject { get; }
    }
}