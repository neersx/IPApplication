using Inprotech.Infrastructure.Extensions;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Extensions
{
    public class StringComparisonExtensionsFacts
    {
        public class IgnoreCaseEqualsMethod
        {
            [Theory]
            [InlineData("abc", "abc", true)]
            [InlineData("", "", true)]
            [InlineData("ANC", "anc", true)]
            [InlineData("Anc", "Abc", false)]
            public void PerformsCaseInsensitiveComparison(string input, string other, bool expected)
            {
                Assert.Equal(expected, input?.IgnoreCaseEquals(other));
            }

            [Fact]
            public void ReturnFalseForNull()
            {
                Assert.False(((string) null).IgnoreCaseEquals("abc"));
            }
        }

        public class IgnoreCaseContainsMethod
        {
            [Theory]
            [InlineData("abc", false)]
            [InlineData("ca", false)]
            [InlineData("CALD", false)]
            [InlineData("123", true)]
            [InlineData("def", false)]
            [InlineData("$%^", true)]
            [InlineData("ALDA", true)]
            public void PerformsCaseInsensitiveComparison(string other, bool expected)
            {
                Assert.Equal(expected, "ab c $%^ alda123".IgnoreCaseContains(other));
            }

            [Fact]
            public void ReturnFalseForNull()
            {
                Assert.False(((string) null).IgnoreCaseContains("abc"));
            }
        }

        public class TextContainsMethod
        {
            [Theory]
            [InlineData("abc", true)]
            [InlineData("ca", true)]
            [InlineData("CALD", true)]
            [InlineData("123", true)]
            [InlineData("def", false)]
            [InlineData("$%^", true)]
            public void PerformsAlphaNumericContains(string other, bool expected)
            {
                Assert.Equal(expected, "ab c $%^ alda123".TextContains(other));
            }

            [Fact]
            public void ReturnFalseForNull()
            {
                Assert.False(((string) null).TextContains("abc"));
            }
        }
    }
}