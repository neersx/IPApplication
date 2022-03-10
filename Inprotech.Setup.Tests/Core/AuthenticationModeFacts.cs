using System.Xml.Linq;
using Inprotech.Setup.Core;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class AuthenticationModeFacts
    {
        readonly IAuthenticationMode _subject = new AuthenticationMode();

        [Theory]
        [InlineData("Windows")]
        [InlineData("Forms")]
        public void ReturnsAuthenticationModeFromCurrentWebConfigs(string mode)
        {
            var r = _subject.Resolve(
                                     new XElement("configuration",
                                                  new XElement("location",
                                                               new XElement("system.web",
                                                                            new XElement("authentication",
                                                                                         new XAttribute("mode", mode))))));

            Assert.Equal(mode, r);
        }

        [Theory]
        [InlineData("Windows")]
        [InlineData("Forms")]
        public void ReturnsAuthenticationModeFromOlderWebConfigs(string mode)
        {
            var r = _subject.Resolve(
                                     new XElement("configuration",
                                                  new XElement("system.web",
                                                               new XElement("authentication",
                                                                            new XAttribute("mode", mode)))));

            Assert.Equal(mode, r);
        }

        [Theory]
        [InlineData("Forms", "true", "Forms,Windows")]
        [InlineData("Forms", "false", "Forms")]
        [InlineData("Windows", "false", "Windows")]
        public void ResolveFromBackupConfig(string authMode, string psuedoSso, string result)
        {
            var fileData = new XElement("configuration",
                                        new XElement("appSettings",
                                                     new XElement("add",
                                                                  new XAttribute("key", "SingleSignOn"),
                                                                  new XAttribute("value", psuedoSso))),
                                        new XElement("location",
                                                     new XElement("system.web",
                                                                  new XElement("authentication",
                                                                               new XAttribute("mode", authMode)))));
            var r = _subject.ResolveFromBackupConfig(fileData);

            Assert.Equal(result, r);
        }
    }
}