using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class ClassStringComparerFacts
    {
        readonly ClassStringComparer _subject = new ClassStringComparer();

        [Theory]
        [InlineData("10", "1")]
        [InlineData(null, "1")]
        [InlineData("1", null)]
        [InlineData("01,02", "01,03")]
        [InlineData("01,02", "01")]
        public void ShouldReturnDifferent(string a, string b)
        {
            var r = _subject.Equals(a, b);

            Assert.False(r);
        }

        [Theory]
        [InlineData("01", "01")]
        [InlineData("001", "1")]
        [InlineData("", null)]
        [InlineData(null, null)]
        [InlineData(null, "")]
        [InlineData("01,02", "2,1")]
        [InlineData("01,02", "01,02")]
        [InlineData("01,02", "02,01")]
        [InlineData(" 01 , 02  ", " 02 ,      01  ")]
        public void ShouldReturnSame(string a, string b)
        {
            var r = _subject.Equals(a, b);

            Assert.True(r);
        }
    }
}