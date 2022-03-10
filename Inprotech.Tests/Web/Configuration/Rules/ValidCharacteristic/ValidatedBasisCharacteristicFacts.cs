using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedBasisCharacteristicFacts
    {
        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData(" ")]
        public async Task ReturnsDefaultCharacteristicForEmptyBasisId(string basis)
        {
            var f = new ValidatedBasisCharacteristicFixture();
            var country = Fixture.String();
            var propertyType = Fixture.String();
            var caseType = Fixture.String();
            var caseCategoryId = Fixture.String();

            var result = f.Subject.GetBasis(basis, caseType, caseCategoryId, propertyType, country);

            Assert.True(result.IsValid);
            Assert.Null(result.Code);
            Assert.Null(result.Key);
            Assert.Null(result.Value);
        }
        
        [Fact]
        public async Task ReturnsValidBasisIfFound()
        {
            var f = new ValidatedBasisCharacteristicFixture();
            var basis = Fixture.String();
            var country = Fixture.String();
            var propertyType = Fixture.String();
            var caseType = Fixture.String();
            var caseCategory = Fixture.String();
            var basisValue = Fixture.String();
            f.Basis.Get(caseType, Arg.Is<string[]>(_ => _[0] == country), Arg.Is<string[]>(_ => _[0] == propertyType), Arg.Is<string[]>(_ => _[0] == caseCategory)).Returns(new[] {new KeyValuePair<string, string>(basis, basisValue)});

            var result = f.Subject.GetBasis(basis, caseType, caseCategory, propertyType, country);

            Assert.True(result.IsValid);
            Assert.Equal(basis, result.Code);
            Assert.Equal(basis, result.Key);
            Assert.Equal(basisValue, result.Value);
        }

        [Fact]
        public async Task ReturnsBasisIfFoundButInvalid()
        {
            var f = new ValidatedBasisCharacteristicFixture();
            var basis = Fixture.String();
            var country = Fixture.String();
            var propertyType = Fixture.String();
            var caseType = Fixture.String();
            var caseCategory = Fixture.String();
            var basisValue = Fixture.String();
            f.Basis.Get(null, Arg.Is<string[]>(_ => !_.Any()), Arg.Is<string[]>(_ => !_.Any()), Arg.Is<string[]>(_ => !_.Any())).Returns(new[] {new KeyValuePair<string, string>(basis, basisValue)});
            
            var result = f.Subject.GetBasis(basis, caseType, caseCategory, propertyType, country);

            Assert.False(result.IsValid);
            Assert.Equal(basis, result.Code);
            Assert.Equal(basis, result.Key);
            Assert.Equal(basisValue, result.Value);
        }

        public class ValidatedBasisCharacteristicFixture : IFixture<ValidatedBasisCharacteristic>
        {
            public ValidatedBasisCharacteristicFixture()
            {
                Basis = Substitute.For<IBasis>();
                Subject = new ValidatedBasisCharacteristic(Basis);
            }
            public IBasis Basis { get; set; }
            public ValidatedBasisCharacteristic Subject { get; set; }
        }
    }
}
