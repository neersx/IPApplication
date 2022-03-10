using Inprotech.Web.Accounting;
using Xunit;

namespace Inprotech.Tests.Web.Accounting
{
    public class AgeingBracketsFacts : FactBase
    {
        [Fact]
        public void ReturnsDefaultBracketValues()
        {
            var f = new AgeingBrackets();
            Assert.Equal(30, f.Current);
            Assert.Equal(60, f.Previous);
            Assert.Equal(90, f.Last);
        }

        [Theory]
        [InlineData(null, 60)]
        [InlineData(0, 0)]
        [InlineData(100, 200)]
        public void ReturnsDefaultPreviousBracketBasedOnCurrent(int? bracket0, int expected)
        {
            var f = new AgeingBrackets {Bracket0 = bracket0};
            Assert.Equal(expected, f.Previous);
        }

        [Theory]
        [InlineData(null, 90)]
        [InlineData(0, 0)]
        [InlineData(100, 300)]
        public void ReturnsDefaultLastBracketBasedOnCurrent(int? bracket0, int expected)
        {
            var f = new AgeingBrackets {Bracket0 = bracket0};
            Assert.Equal(expected, f.Last);
        }
    }
}
