using System.Xml.Linq;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Microsoft.Web.Administration;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class AvailableFeaturesFacts
    {
        readonly IAvailableFeatures _subject = new AvailableFeatures();

        [Fact]
        public void AlsoResolveInClassicModeWhenNotWrappedInLocation()
        {
            /* it is not wrapped around location node */

            var r = _subject.Resolve(
                                     new XElement("configuration",
                                                  new XElement("system.web",
                                                               new XElement("httpModules",
                                                                            new XElement("add",
                                                                                         new XAttribute("name", "AppsBridgeHttpModule"))))),
                                     ManagedPipelineMode.Classic);

            Assert.Contains(IisAppFeatures.AppsBridgeHttpModule, r);
        }

        [Fact]
        public void AlsoResolveIntegratedPipelineModeWhenNotWrappedInLocation()
        {
            /* it is not wrapped around location node */

            var r = _subject.Resolve(
                                     new XElement("configuration",
                                                  new XElement("system.webServer",
                                                               new XElement("modules",
                                                                            new XElement("add",
                                                                                         new XAttribute("name", "AppsBridgeHttpModule"))))),
                                     ManagedPipelineMode.Integrated);

            Assert.Contains(IisAppFeatures.AppsBridgeHttpModule, r);
        }

        [Fact]
        public void ResolvesClassicModeWithAppsBridgeHttpModule()
        {
            var r = _subject.Resolve(
                                     new XElement("configuration",
                                                  new XElement("location",
                                                               new XElement("system.web",
                                                                            new XElement("httpModules",
                                                                                         new XElement("add",
                                                                                                      new XAttribute("name", "AppsBridgeHttpModule")))))),
                                     ManagedPipelineMode.Classic);

            Assert.Contains(IisAppFeatures.AppsBridgeHttpModule, r);
        }

        [Fact]
        public void ResolvesClassicModeWithoutAppsBridgeHttpModule()
        {
            var r = _subject.Resolve(
                                     new XElement("configuration",
                                                  new XElement("location",
                                                               new XElement("system.web",
                                                                            new XElement("httpModules")))),
                                     ManagedPipelineMode.Classic);

            Assert.DoesNotContain(IisAppFeatures.AppsBridgeHttpModule, r);
        }

        [Fact]
        public void ResolvesIntegratedPipelineModeWithAppsBridgeHttpModule()
        {
            var r = _subject.Resolve(
                                     new XElement("configuration",
                                                  new XElement("location",
                                                               new XElement("system.webServer",
                                                                            new XElement("modules",
                                                                                         new XElement("add",
                                                                                                      new XAttribute("name", "AppsBridgeHttpModule")))))),
                                     ManagedPipelineMode.Integrated);

            Assert.Contains(IisAppFeatures.AppsBridgeHttpModule, r);
        }

        [Fact]
        public void ResolvesIntegratedPipelineModeWithoutAppsBridgeHttpModule()
        {
            var r = _subject.Resolve(
                                     new XElement("configuration",
                                                  new XElement("location",
                                                               new XElement("system.webServer",
                                                                            new XElement("modules")))),
                                     ManagedPipelineMode.Integrated);

            Assert.DoesNotContain(IisAppFeatures.AppsBridgeHttpModule, r);
        }
    }
}