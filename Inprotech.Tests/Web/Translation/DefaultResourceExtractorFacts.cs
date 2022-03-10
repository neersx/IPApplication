using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.Translation;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Translation
{
    public class DefaultResourceExtractorFacts
    {
        readonly IResourceFile _resourceFile = Substitute.For<IResourceFile>();

        [Fact]
        public async Task ExtractsFromTranslationEn()
        {
            var json = new
            {
                a = "something value",
                b = new
                {
                    b1 = new
                    {
                        b11 = new
                        {
                            b111 = "something else"
                        }
                    }
                }
            };

            _resourceFile.ReadAsync(KnownPaths.Translations)
                         .Returns(JObject.FromObject(json).ToString());

            var subject = new DefaultResourceExtractor(_resourceFile);

            var r = (await subject.Extract()).ToArray();

            var r1 = r.First();
            var r2 = r.Last();

            Assert.Equal("condor", r1.Source);
            Assert.Equal("condor-global", r1.Area);
            Assert.Equal("a", r1.ResourceKey);
            Assert.Equal("something value", r1.Default);

            Assert.Equal("condor", r2.Source);
            Assert.Equal("condor-b", r2.Area);
            Assert.Equal("b.b1.b11.b111", r2.ResourceKey);
            Assert.Equal("something else", r2.Default);
        }
    }
}