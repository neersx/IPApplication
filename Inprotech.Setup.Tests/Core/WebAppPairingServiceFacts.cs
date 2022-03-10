using System.Linq;
using Inprotech.Setup.Core;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class WebAppPairingServiceFacts
    {
        public WebAppPairingServiceFacts()
        {
            _service = new WebAppPairingService();
        }

        readonly WebAppPairingService _service;

        [Fact]
        public void ShouldFindPairedIisApp()
        {
            var iisApp = new IisAppInfo {Site = "a", VirtualPath = "b"};
            var webApp = new WebAppInfo("a", null, new SetupSettings {IisSite = "A", IisPath = "b"}, null);

            var found = _service.FindPairedIisApp(new[] {iisApp}, webApp);
            Assert.Equal(iisApp, found);
        }

        [Fact]
        public void ShouldFindPairedWebApp()
        {
            var iisApp = new IisAppInfo {Site = "a", VirtualPath = "b"};
            var webApp = new WebAppInfo("a", null, new SetupSettings {IisSite = "a", IisPath = "B"}, null);

            var found = _service.FindPairedWebApp(new[] {webApp}, iisApp);
            Assert.Equal(webApp, found);
        }

        [Fact]
        public void ShouldFindUnpairedIisApp()
        {
            var iisApp = new IisAppInfo {Site = "a", VirtualPath = "b"};
            var webApp = new WebAppInfo("a", null, new SetupSettings {IisSite = "c", IisPath = "d"}, null);

            var found = _service.FindUnpairedIisApp(new[] {webApp}, new[] {iisApp});
            Assert.Equal(iisApp, found.Single());
        }
    }
}