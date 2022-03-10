using System.Linq;
using Inprotech.Infrastructure;
using Xunit;

namespace Inprotech.Tests.Hosting
{
    public class HttpListenerAddressParserFacts
    {
        [Theory]
        [InlineData("foo")]
        [InlineData("/foo")]
        [InlineData("/foo/")]
        [InlineData(" foo ")]
        [InlineData(" /foo/ ")]
        public void AllAddressesIncludeParentPath(string parentPath)
        {
            var a = HttpListenerAddressParser.Parse("http://a:80", parentPath, "x,y");

            Assert.Equal(2, a.Count());
            Assert.Contains("http://a:80/foo/x", a);
            Assert.Contains("http://a:80/foo/y", a);
        }

        [Fact]
        public void FixesBackSlash()
        {
            Assert.Equal("http://a:80/x/y/z", HttpListenerAddressParser.Parse(@"http:\\a:80\", string.Empty, @"x\y\z").Single());
        }

        [Fact]
        public void IgnoresEmptyEntries()
        {
            Assert.Equal("http://a:80/x", HttpListenerAddressParser.Parse("http://a:80,, ,\t", string.Empty, "x,, ,\t").Single());
        }

        [Fact]
        public void RemovesLeadingAndTrailingSpaces()
        {
            Assert.Equal("http://a:80/x", HttpListenerAddressParser.Parse(" http://a:80 ", string.Empty, " x ").Single());
        }

        [Fact]
        public void ReturnsAnAddressForEachBaseUrl()
        {
            var a = HttpListenerAddressParser.Parse("http://a:80, http://b:80, ", string.Empty, "x");

            Assert.Equal(2, a.Count());
            Assert.Contains("http://a:80/x", a);
            Assert.Contains("http://b:80/x", a);
        }

        [Fact]
        public void ReturnsAnAddressForEachPath()
        {
            var a = HttpListenerAddressParser.Parse("http://a:80, ", string.Empty, "x,y");

            Assert.Equal(2, a.Count());
            Assert.Contains("http://a:80/x", a);
            Assert.Contains("http://a:80/y", a);
        }
    }
}