using System.Collections.Generic;
using System.Linq;
using Inprotech.Setup.Actions;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class ContextExtensionsFacts
    {
        [Theory]
        [InlineData("http://*:80", "apps")]
        [InlineData("http://*:80,https://*:443", "apps")]
        public void ShouldBuildBindingUrlsForSpecifiedPath(string bindingUrls, string path)
        {
            var context = new Dictionary<string, object> {{"BindingUrls", bindingUrls}};

            var urls = context.BindingUrls(path).ToArray();

            foreach (var url in bindingUrls.Split(','))
                Assert.Contains(url + "/" + path, urls);
        }

        [Fact]
        public void ShouldNotPrependASlashIfPathAlreadyHasOne()
        {
            var context = new Dictionary<string, object> {{"BindingUrls", "http://*:80"}};

            Assert.Equal("http://*:80/a", context.BindingUrls("/a").Single());
        }
    }
}