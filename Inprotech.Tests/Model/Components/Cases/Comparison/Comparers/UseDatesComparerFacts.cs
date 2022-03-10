using System;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class UseDatesComparerFacts
    {
        readonly UseDateComparer _subject = new UseDateComparer();

        [Theory]
        [InlineData("20141011", "2014-10-11", "P")]
        [InlineData("20141000", "2014-10-31", "MonthYear")]
        [InlineData("20140000", "2014-12-31", "Year")]
        public void IdentifiesFormat(string firstUseDate, string expectedFirstUseDate, string expectedFormat)
        {
            var r = _subject.Compare(null, firstUseDate);

            Assert.Equal(expectedFirstUseDate, r.TheirValue.GetValueOrDefault().ToString("yyyy-MM-dd"));
            Assert.Equal(expectedFormat, r.Format);
        }

        [Theory]
        [InlineData("2014-01-01", "20140101", false)]
        [InlineData("2014-01-02", "20140101", true)]
        public void ComparesDateInFull(string input, string source, bool expected)
        {
            var d = DateTime.Parse(input);

            var r = _subject.Compare(d, source);

            Assert.Equal(expected, r.Different);
            Assert.Equal(expected, r.Updateable);
            Assert.Equal("P", r.Format);
        }

        [Theory]
        [InlineData("2014-01-01", false)]
        [InlineData("2014-01-31", false)]
        [InlineData("2014-02-01", true)]
        [InlineData("2013-12-31", true)]
        public void ComparesWithOnlyMonthYear(string input, bool expected)
        {
            var d = DateTime.Parse(input);

            var r = _subject.Compare(d, "20140100");

            Assert.Equal(expected, r.Different);
            Assert.Equal(expected, r.Updateable);
            Assert.Equal("MonthYear", r.Format);
        }

        [Theory]
        [InlineData("2014-01-01", false)]
        [InlineData("2014-12-31", false)]
        [InlineData("2015-01-01", true)]
        [InlineData("2013-12-31", true)]
        public void ComparesWithOnlyYear(string input, bool expected)
        {
            var d = DateTime.Parse(input);

            var r = _subject.Compare(d, "20140000");

            Assert.Equal(expected, r.Different);
            Assert.Equal(expected, r.Updateable);
            Assert.Equal("Year", r.Format);
        }

        [Theory]
        [InlineData("rubbish")]
        [InlineData("2140101")]
        public void ComparesWithInvalidDate(string input)
        {
            var r = _subject.Compare(DateTime.Today, input);

            Assert.True(r.Different.GetValueOrDefault());
            Assert.False(r.Updateable.GetValueOrDefault());
            Assert.True(r.HasParseError());
        }

        [Fact]
        public void UpdatableWhenNull()
        {
            var r = _subject.Compare(null, "20140101");

            Assert.True(r.Different.GetValueOrDefault());
            Assert.True(r.Updateable.GetValueOrDefault());
        }
    }
}