using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedActionCharacteristicFacts
    {
        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData(" ")]
        public async Task ReturnsDefaultCharacteristicForEmptyActionId(string actionId)
        {
            var f = new ValidatedActionCharacteristicFixture();
            var country = Fixture.String();
            var propertyType = Fixture.String();
            var caseType = Fixture.String();

            var result = f.Subject.GetAction(actionId, country, propertyType, caseType);

            Assert.True(result.IsValid);
            Assert.Null(result.Code);
            Assert.Null(result.Key);
            Assert.Null(result.Value);
        }

        [Fact]
        public async Task ReturnsValidActionIfFound()
        {
            var f = new ValidatedActionCharacteristicFixture();
            var actionId = Fixture.String();
            var country = Fixture.String();
            var propertyType = Fixture.String();
            var caseType = Fixture.String();
            var name = Fixture.String();
            f.Actions.Get(country, propertyType, caseType).Returns(new List<ActionData> {new ActionData() {Code = actionId, Name = name}});

            var result = f.Subject.GetAction(actionId, country, propertyType, caseType);

            Assert.True(result.IsValid);
            Assert.Equal(actionId, result.Code);
            Assert.Equal(actionId, result.Key);
            Assert.Equal(name, result.Value);
        }
        
        [Fact]
        public async Task ReturnsActionIfFoundButInvalid()
        {
            var f = new ValidatedActionCharacteristicFixture();
            var actionId = Fixture.String();
            var country = Fixture.String();
            var propertyType = Fixture.String();
            var caseType = Fixture.String();
            var name = Fixture.String();
            f.Actions.Get(null, null, null).Returns(new List<ActionData> { new ActionData() { Code = actionId, Name = name } });

            var result = f.Subject.GetAction(actionId, country, propertyType, caseType);

            Assert.False(result.IsValid);
            Assert.Equal(actionId, result.Code);
            Assert.Equal(actionId, result.Key);
            Assert.Equal(name, result.Value);
        }

        public class ValidatedActionCharacteristicFixture : IFixture<ValidatedActionCharacteristic>
        {
            public ValidatedActionCharacteristicFixture()
            {
                Actions = Substitute.For<IActions>();
                Subject = new ValidatedActionCharacteristic(Actions);
            }
            public IActions Actions { get; set; }
            public ValidatedActionCharacteristic Subject { get; set; }
        }
    }
}
