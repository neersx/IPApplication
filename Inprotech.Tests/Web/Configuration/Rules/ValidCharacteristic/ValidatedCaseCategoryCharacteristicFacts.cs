using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedCaseCategoryCharacteristicFacts
    {
        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData(" ")]
        public async Task ReturnsDefaultCharacteristicForEmptyCaseCategoryId(string caseCategory)
        {
            var f = new ValidatedCaseCategoryCharacteristicFixture();
            var country = Fixture.String();
            var propertyType = Fixture.String();
            var caseType = Fixture.String();

            var result = f.Subject.GetCaseCategory(caseCategory, caseType, propertyType, country);

            Assert.True(result.IsValid);
            Assert.Null(result.Code);
            Assert.Null(result.Key);
            Assert.Null(result.Value);
        }
        
        [Fact]
        public async Task ReturnsValidCaseCategoryIfFound()
        {
            var f = new ValidatedCaseCategoryCharacteristicFixture();
            var caseCategory = Fixture.String();
            var country = Fixture.String();
            var propertyType = Fixture.String();
            var caseType = Fixture.String();
            var caseCategoryValue = Fixture.String();
            f.CaseCategory.Get(null, caseType, Arg.Is<string[]>(_ => _[0] == country), Arg.Is<string[]>(_ => _[0] == propertyType)).Returns(new[] {new KeyValuePair<string, string>(caseCategory, caseCategoryValue)});

            var result = f.Subject.GetCaseCategory(caseCategory, caseType, propertyType, country);

            Assert.True(result.IsValid);
            Assert.Equal(caseCategory, result.Code);
            Assert.Equal(caseCategory, result.Key);
            Assert.Equal(caseCategoryValue, result.Value);
        }

        [Fact]
        public async Task ReturnsCaseCategoryIfFoundButInvalid()
        {
            var f = new ValidatedCaseCategoryCharacteristicFixture();
            var caseCategory = Fixture.String();
            var country = Fixture.String();
            var propertyType = Fixture.String();
            var caseType = Fixture.String();
            var caseCategoryValue = Fixture.String();
            f.CaseCategory.Get(null, caseType, Arg.Is<string[]>(_ => !_.Any()), Arg.Is<string[]>(_ => !_.Any())).Returns(new[] {new KeyValuePair<string, string>(caseCategory, caseCategoryValue)});
            
            var result = f.Subject.GetCaseCategory(caseCategory, caseType, propertyType, country);

            Assert.False(result.IsValid);
            Assert.Equal(caseCategory, result.Code);
            Assert.Equal(caseCategory, result.Key);
            Assert.Equal(caseCategoryValue, result.Value);
        }

        public class ValidatedCaseCategoryCharacteristicFixture : IFixture<ValidatedCaseCategoryCharacteristic>
        {
            public ValidatedCaseCategoryCharacteristicFixture()
            {
                CaseCategory = Substitute.For<ICaseCategories>();
                Subject = new ValidatedCaseCategoryCharacteristic(CaseCategory);
            }
            public ICaseCategories CaseCategory { get; set; }
            public ValidatedCaseCategoryCharacteristic Subject { get; set; }
        }
    }
}
