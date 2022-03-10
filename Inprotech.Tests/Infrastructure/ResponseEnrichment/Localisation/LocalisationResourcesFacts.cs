using System.Collections.Generic;
using Inprotech.Infrastructure.ResponseEnrichment.Localisation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.ResponseEnrichment.Localisation
{
    public class LocalisationResourcesFacts
    {
        public class LocalisationResourcesFixture : IFixture<LocalisationResources>
        {
            public LocalisationResourcesFixture()
            {
                ResourceLoader = Substitute.For<IResourceLoader>();

                Subject = new LocalisationResources(ResourceLoader);
            }

            public IResourceLoader ResourceLoader { get; set; }
            public LocalisationResources Subject { get; }
        }

        public class ForMethod
        {
            [Fact]
            public void ReturnsMultipleApplicationSpecificResources()
            {
                var f = new LocalisationResourcesFixture();

                const string app = "app1";
                const string dependentComponent = "app2";

                f.ResourceLoader.TryLoadResources(Arg.Is<string>(s => s.StartsWith("resources/app1/en-US.json")), out _)
                 .Returns(x =>
                 {
                     x[1] = new Dictionary<string, object> {{"a", "aaa"}};
                     return true;
                 });

                f.ResourceLoader.TryLoadResources(Arg.Is<string>(s => s.StartsWith("resources/app2/en-US.json")), out _)
                 .Returns(x =>
                 {
                     x[1] = new Dictionary<string, object> {{"b", "bbb"}};
                     return true;
                 });

                var result = f.Subject.For(new[] {app, dependentComponent}, new[] {"en-US"});

                Assert.Equal("aaa", result["a"].ToString());
                Assert.Equal("bbb", result["b"].ToString());
            }

            [Fact]
            public void ReturnsNothingIfResourceUnavailable()
            {
                var f = new LocalisationResourcesFixture();

                f.ResourceLoader.TryLoadResources(Arg.Any<string>(), out _)
                 .Returns(x =>
                 {
                     x[1] = new Dictionary<string, object>();
                     return false;
                 });

                Assert.Empty(f.Subject.For(new[] {"nothing"}, new[] {"en-US"}));
            }
        }
    }
}