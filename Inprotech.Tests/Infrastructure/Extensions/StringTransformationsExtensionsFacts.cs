using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Extensions
{
    public class StringTransformationsExtensionsFacts
    {
        public class AsArrayOrNullMethod
        {
            [Theory]
            [InlineData("")]
            [InlineData(null)]
            public void ReturnsNull(string input)
            {
                Assert.Null(input.AsArrayOrNull());
            }

            [Fact]
            public void ReturnsAsArray()
            {
                var input = Fixture.String();
                var result = input.AsArrayOrNull();

                Assert.Equal(result.Single(), input);
            }
        }

        public class WhiteSpaceAsNullMethod
        {
            [Theory]
            [InlineData("")]
            [InlineData("            ")]
            [InlineData(null)]
            public void ReturnsAsNull(string input)
            {
                Assert.Null(input.WhiteSpaceAsNull());
            }

            [Fact]
            public void ReturnsInput()
            {
                var input = Fixture.String();

                Assert.Equal(input, input.WhiteSpaceAsNull());
            }
        }

        public class ToCamelCaseMethod
        {
            [Theory]
            [InlineData("", "")]
            [InlineData(null, null)]
            [InlineData("abcd efgh", "abcdEfgh")]
            [InlineData("abcd-efgh", "abcd-efgh")]
            [InlineData("Abcd", "abcd")]
            public void ConvertsInputToCamelCase(string input, string expected)
            {
                Assert.Equal(expected, input?.ToCamelCase());
            }
        }

        public class CamelCaseToUnderscoreMethod
        {
            [Theory]
            [InlineData("", "")]
            [InlineData(null, null)]
            [InlineData("abcd efgh", "ABCD EFGH")]
            [InlineData("abcd-efgh", "ABCD-EFGH")]
            [InlineData("Abcd", "ABCD")]
            [InlineData("DoThisProperly", "DO_THIS_PROPERLY")]
            public void ConvertsCamelCaseInputToUnderscoredUpper(string input, string expected)
            {
                Assert.Equal(expected, input?.CamelCaseToUnderscore());
            }
        }

        public class ToHypenatedLowerCaseMethod
        {
            [Theory]
            [InlineData("", "")]
            [InlineData(null, null)]
            [InlineData("abcd efgh", "abcd-efgh")]
            [InlineData("abcd-efgh", "abcd-efgh")]
            [InlineData("Abcd", "abcd")]
            [InlineData("DoThisProperly", "do-this-properly")]
            public void CovertsInputToHypenatedLowerCase(string input, string expected)
            {
                Assert.Equal(expected, input?.ToHyphenatedLowerCase());
            }
        }

        public class StripNonAlphanumericsMethod
        {
            [Theory]
            [InlineData("a b c#$%^%&^@*#^akjh1329#$%^&*(", "abcakjh1329")]
            public void RemovesNonAlphanumericCharactersFromInput(string input, string expected)
            {
                Assert.Equal(expected, input.StripNonAlphanumerics());
            }
        }
    }
}