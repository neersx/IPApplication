using System.Threading.Tasks;
using Inprotech.Web.Portal;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Portal
{
    public class LinksControllerFacts
    {
        [Fact]
        public async Task ShouldReturnLinks()
        {
            var r = new[]
            {
                new LinksViewModel(),
                new LinksViewModel()
            };

            var links = Substitute.For<ILinksResolver>();
            links.Resolve().Returns(r);

            Assert.Equal(r, await new LinksController(links).GetLinks());
        }
    }
}