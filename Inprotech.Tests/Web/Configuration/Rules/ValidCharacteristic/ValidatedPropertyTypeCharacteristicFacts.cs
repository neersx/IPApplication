using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedPropertyTypeCharacteristicFacts
    {
        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData(" ")]
        public async Task ReturnsDefaultCharacteristicForEmptyPropertyTypeId(string propertyType)
        {
            var f = new ValidatedPropertyTypeCharacteristicFixture();
            var country = Fixture.String();

            var result = f.Subject.GetPropertyType(propertyType, country);

            Assert.True(result.IsValid);
            Assert.Null(result.Code);
            Assert.Null(result.Key);
            Assert.Null(result.Value);
        }
        
        [Fact]
        public async Task ReturnsValidPropertyTypeIfFound()
        {
            var f = new ValidatedPropertyTypeCharacteristicFixture();
            var propertyType = Fixture.String();
            var country = Fixture.String();
            var propertyTypeValue = Fixture.String();
            f.PropertyType.Get(null, Arg.Is<string[]>(_ => _[0] == country)).Returns(new[] {new KeyValuePair<string, string>(propertyType, propertyTypeValue)});

            var result = f.Subject.GetPropertyType(propertyType, country);

            Assert.True(result.IsValid);
            Assert.Equal(propertyType, result.Code);
            Assert.Equal(propertyType, result.Key);
            Assert.Equal(propertyTypeValue, result.Value);
        }

        [Fact]
        public async Task ReturnsPropertyTypeIfFoundButInvalid()
        {
            var f = new ValidatedPropertyTypeCharacteristicFixture();
            var propertyType = Fixture.String();
            var country = Fixture.String();
            var propertyTypeValue = Fixture.String();
            f.PropertyType.Get(null, Arg.Is<string[]>(_ => !_.Any())).Returns(new[] {new KeyValuePair<string, string>(propertyType, propertyTypeValue)});
            
            var result = f.Subject.GetPropertyType(propertyType, country);

            Assert.False(result.IsValid);
            Assert.Equal(propertyType, result.Code);
            Assert.Equal(propertyType, result.Key);
            Assert.Equal(propertyTypeValue, result.Value);
        }

        public class ValidatedPropertyTypeCharacteristicFixture : IFixture<ValidatedPropertyTypeCharacteristic>
        {
            public ValidatedPropertyTypeCharacteristicFixture()
            {
                PropertyType = Substitute.For<IPropertyTypes>();
                Subject = new ValidatedPropertyTypeCharacteristic(PropertyType);
            }
            public IPropertyTypes PropertyType { get; set; }
            public ValidatedPropertyTypeCharacteristic Subject { get; set; }
        }
    }
}
