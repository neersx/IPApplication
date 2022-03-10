using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment.Localisation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.ResponseEnrichment.Localisation
{
    public class ResourcesFacts
    {
        readonly IFileHelpers _fileHelpers = Substitute.For<IFileHelpers>();
        const string PathTemplate = "condor/localisation/translations/translations_{0}.json";

        [Theory]
        [InlineData("fr-FR", "fr")]
        [InlineData(null, "fr")]
        [InlineData("fr-FR", null)]
        [InlineData(null, null)]
        public void ShouldNotReturnAnythingIfNotFound(string culture, string fallbackCulture)
        {
            _fileHelpers.Exists(Arg.Any<string>()).Returns(false);

            Assert.Empty(new Resources(_fileHelpers).Resolve(culture, fallbackCulture));
        }

        [Fact]
        public void ShouldReturnBothWithFallbackFirst()
        {
            _fileHelpers.Exists(Arg.Any<string>()).Returns(true);
            var fallbackPath = string.Format(PathTemplate, "fr");
            var specificPath = string.Format(PathTemplate, "fr-FR");

            var subject = new Resources(_fileHelpers);

            var result = subject.Resolve("fr-FR", "fr").ToArray();

            Assert.Equal("fr", result.First().Code);
            Assert.Equal("fr-FR", result.Last().Code);
            Assert.Equal(fallbackPath, result.First().Path);
            Assert.Equal(specificPath, result.Last().Path);
        }

        [Fact]
        public void ShouldReturnFallbackResourceFound()
        {
            _fileHelpers.Exists(Arg.Any<string>()).Returns(true);
            var frPath = string.Format(PathTemplate, "fr");

            var subject = new Resources(_fileHelpers);

            var result = subject.Resolve(null, "fr").ToArray();

            Assert.Equal("fr", result.Single().Code);
            Assert.Equal(frPath, result.Single().Path);
        }

        [Fact]
        public void ShouldReturnResourceFound()
        {
            _fileHelpers.Exists(Arg.Any<string>()).Returns(true);
            var frPath = string.Format(PathTemplate, "fr-FR");

            var subject = new Resources(_fileHelpers);

            var result = subject.Resolve("fr-FR", null).ToArray();

            Assert.Equal("fr-FR", result.Single().Code);
            Assert.Equal(frPath, result.Single().Path);
        }
    }
}