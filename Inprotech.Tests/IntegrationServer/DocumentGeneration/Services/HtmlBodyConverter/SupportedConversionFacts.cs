using Inprotech.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter
{
    public class SupportedConversionFacts
    {
        [Theory]
        [InlineData(".docx")]
        [InlineData(".doc")]
        [InlineData(".docm")]
        [InlineData(".dotx")]
        [InlineData(".dotm")]
        public void ShouldResolveToWord(string fileExtension)
        {
            var filePath = Fixture.String() + fileExtension;

            Assert.Equal(Category.Word, CategoryResolver.Resolve(filePath));
        }

        [Fact]
        public void ShouldResolveToUnknown()
        {
            Assert.Equal(Category.Unknown, CategoryResolver.Resolve(Fixture.String()));
        }
    }
}