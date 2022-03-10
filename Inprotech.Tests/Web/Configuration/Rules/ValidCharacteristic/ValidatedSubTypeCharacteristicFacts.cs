using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedSubTypeCharacteristicFacts
    {
        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData(" ")]
        public async Task ReturnsDefaultCharacteristicForEmptySubTypeId(string subType)
        {
            var f = new ValidatedSubTypeCharacteristicFixture();
            var country = Fixture.String();
            var caseType = Fixture.String();
            var caseCategory = Fixture.String();
            var propertyType = Fixture.String();

            var result = f.Subject.GetSubType(subType, caseType, caseCategory, propertyType, country);

            Assert.True(result.IsValid);
            Assert.Null(result.Code);
            Assert.Null(result.Key);
            Assert.Null(result.Value);
        }

        [Fact]
        public async Task ReturnsValidSubTypeIfFound()
        {
            var f = new ValidatedSubTypeCharacteristicFixture();
            var subType = Fixture.String();
            var country = Fixture.String();
            var caseType = Fixture.String();
            var caseCategory = Fixture.String();
            var propertyType = Fixture.String();
            var subTypeValue = Fixture.String();
            f.SubType.Get(caseType,
                          Arg.Is<string[]>(_ => _[0] == country), 
                          Arg.Is<string[]>(_ => _[0] == propertyType), 
                          Arg.Is<string[]>(_ => _[0] == caseCategory)).Returns(new[] { new KeyValuePair<string, string>(subType, subTypeValue) });

            var result = f.Subject.GetSubType(subType, caseType, caseCategory, propertyType, country);

            Assert.True(result.IsValid);
            Assert.Equal(subType, result.Code);
            Assert.Equal(subType, result.Key);
            Assert.Equal(subTypeValue, result.Value);
        }

        [Fact]
        public async Task ReturnsSubTypeIfFoundButInvalid()
        {
            var f = new ValidatedSubTypeCharacteristicFixture();
            var subType = Fixture.String();
            var country = Fixture.String();
            var caseType = Fixture.String();
            var caseCategory = Fixture.String();
            var propertyType = Fixture.String();
            var subTypeValue = Fixture.String();
            f.SubType.Get(null, Arg.Is<string[]>(_ => !_.Any()), Arg.Is<string[]>(_ => !_.Any()), Arg.Is<string[]>(_ => !_.Any())).Returns(new[] { new KeyValuePair<string, string>(subType, subTypeValue) });

            var result = f.Subject.GetSubType(subType, caseType, caseCategory, propertyType, country);

            Assert.False(result.IsValid);
            Assert.Equal(subType, result.Code);
            Assert.Equal(subType, result.Key);
            Assert.Equal(subTypeValue, result.Value);
        }

        public class ValidatedSubTypeCharacteristicFixture : IFixture<ValidatedSubTypeCharacteristic>
        {
            public ValidatedSubTypeCharacteristicFixture()
            {
                SubType = Substitute.For<ISubTypes>();
                Subject = new ValidatedSubTypeCharacteristic(SubType);
            }
            public ISubTypes SubType { get; set; }
            public ValidatedSubTypeCharacteristic Subject { get; set; }
        }
    }
}
