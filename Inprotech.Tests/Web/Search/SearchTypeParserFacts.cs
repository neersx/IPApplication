using System;
using Inprotech.Web.Search;
using Xunit;

namespace Inprotech.Tests.Web.Search
{
    public class SearchTypeParserFacts
    {
        [Theory]
        [InlineData("quick-search", SearchConstants.SearchTypeQuickSearch)]
        [InlineData("standard-search", SearchConstants.SearchTypeStandardSearch)]
        public void ShouldParseSearchType(string source, int target)
        {
            Assert.Equal(target, new SearchTypeParser().Parse(source));
        }

        [Fact]
        public void ThrowsExceptionIfSearchTypeIsInvalid()
        {
            Assert.Throws<ArgumentException>(() => { new SearchTypeParser().Parse("invalid-type"); });
        }
    }
}