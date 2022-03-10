using System;
using System.Globalization;
using System.Threading.Tasks;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedDefaultDateOfLawCharacteristicFacts : FactBase
    {

        public class GetDefaultDateOfLawMethod : FactBase
        {
            [Fact]
            public async Task PassesTheCaseAndAction()
            {
                var f = new ValidatedDefaultDateOfLawCharacteristicFixture();
                var caseId = Fixture.Integer();
                var actionId = Fixture.String();
                f.Subject.GetDefaultDateOfLaw(caseId, actionId);
                f.DateOfLaw.Received(1).GetDefaultDateOfLaw(caseId, actionId);
            }
            
            [Fact]
            public async Task ReturnsEmptyValidatedCharacteristicWhenNoDateOfLaw()
            {
                var f = new ValidatedDefaultDateOfLawCharacteristicFixture();
                var caseId = Fixture.Integer();
                var actionId = Fixture.String();
                var result = f.Subject.GetDefaultDateOfLaw(caseId, actionId);

                Assert.True(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }

            [Theory]
            [InlineData(null)]
            [InlineData("")]
            [InlineData(" ")]
            public async Task ReturnsEmptyValidatedCharacteristicWhenNoActionId(string actionId)
            {
                var f = new ValidatedDefaultDateOfLawCharacteristicFixture();
                var caseId = Fixture.Integer();
                var result = f.Subject.GetDefaultDateOfLaw(caseId, actionId);

                Assert.True(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }

            [Fact]
            public async Task ReturnsValidatedCharacteristicWhenDateOfLawReturned()
            {
                var f = new ValidatedDefaultDateOfLawCharacteristicFixture();
                var caseId = Fixture.Integer();
                var actionId = Fixture.String();
                var expectedDate = Fixture.PastDate();
                f.DateOfLaw.GetDefaultDateOfLaw(Arg.Any<int>(), Arg.Any<string>()).ReturnsForAnyArgs(expectedDate);
                var result = f.Subject.GetDefaultDateOfLaw(caseId, actionId);

                Assert.True(result.IsValid);
                Assert.Equal(expectedDate.ToString(CultureInfo.InvariantCulture), result.Code);
                Assert.Equal(expectedDate, DateTime.Parse(result.Value));
            }
        }

        public class ValidatedDefaultDateOfLawCharacteristicFixture : IFixture<ValidatedDefaultDateOfLawCharacteristic>
        {
            public ValidatedDefaultDateOfLawCharacteristicFixture()
            {
                DateOfLaw = Substitute.For<IDateOfLaw>();
               
                FormatDateOfLaw = Substitute.For<IFormatDateOfLaw>();
                FormatDateOfLaw.AsId(Arg.Any<DateTime>()).Returns(_ => _.ArgAt<DateTime>(0).ToString(CultureInfo.InvariantCulture));
                FormatDateOfLaw.Format(Arg.Any<DateTime>()).Returns(_ => _.ArgAt<DateTime>(0).ToString("dd-MMM-yyyy"));

                Subject = new ValidatedDefaultDateOfLawCharacteristic(DateOfLaw, FormatDateOfLaw);
            }
            public IDateOfLaw DateOfLaw { get; set; }
            public IFormatDateOfLaw FormatDateOfLaw { get; set; }

            public ValidatedDefaultDateOfLawCharacteristic Subject { get; set; }
        }
    }
}
