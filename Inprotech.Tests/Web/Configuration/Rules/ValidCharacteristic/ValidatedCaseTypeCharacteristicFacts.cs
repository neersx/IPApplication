using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedCaseTypeCharacteristicFacts
    {
        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData(" ")]
        public async Task ReturnsDefaultCharacteristicForEmptyCaseTypeId(string caseType)
        {
            var f = new ValidatedCaseTypeCharacteristicFixture();

            var result = f.Subject.GetCaseType(caseType);

            Assert.True(result.IsValid);
            Assert.Null(result.Code);
            Assert.Null(result.Key);
            Assert.Null(result.Value);
        }

        [Fact]
        public async Task ReturnsValidCaseTypeIfFound()
        {
            var f = new ValidatedCaseTypeCharacteristicFixture();
            var caseType = Fixture.String();
            var name = Fixture.String();
            f.CaseTypes.Get().Returns(new List<KeyValuePair<string, string>>() { new KeyValuePair<string, string>(caseType, name) });

            var result = f.Subject.GetCaseType(caseType);

            Assert.True(result.IsValid);
            Assert.Equal(caseType, result.Code);
            Assert.Equal(caseType, result.Key);
            Assert.Equal(name, result.Value);
        }

        public class ValidatedCaseTypeCharacteristicFixture : IFixture<ValidatedCaseTypeCharacteristic>
        {
            public ValidatedCaseTypeCharacteristicFixture()
            {
                CaseTypes = Substitute.For<ICaseTypes>();
                Subject = new ValidatedCaseTypeCharacteristic(CaseTypes);
            }
            public ICaseTypes CaseTypes { get; set; }
            public ValidatedCaseTypeCharacteristic Subject { get; set; }
        }
    }
}
