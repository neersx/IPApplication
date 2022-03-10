using System.Linq;
using System.Xml;
using System.Xml.Linq;
using Inprotech.Setup.Actions.Utilities;
using Xunit;

namespace Inprotech.Setup.Tests.Actions.Utilities
{
    public class ConfigurationUtilitiesFacts
    {
        [Fact]
        public void OverridesExistingSmtpServerDetails()
        {
            var appConfigXml =
                new XElement("configuration",
                             new XElement("system.net",
                                          new XElement("mailSettings",
                                                       new XElement("smtp",
                                                                    new XAttribute("deliveryMethod", "Network"),
                                                                    new XAttribute("from", "foobar@microsoft.com"),
                                                                    new XElement("network",
                                                                                 new XAttribute("defaultCredentials", "true"),
                                                                                 new XAttribute("host", "smtp.microsoft.com")))))
                            ).ToString(SaveOptions.None);

            var doc = new XmlDocument();
            doc.LoadXml(appConfigXml);

            ConfigurationUtility.UpdateSmtpSettings(doc, "smtp.google.com");

            var result = XElement.Parse(doc.InnerXml);

            var smtp = result.Descendants("smtp").Single();
            var network = smtp.Element("network");

            Assert.Equal("smtp.google.com", (string) network.Attribute("host"));
        }

        [Fact]
        public void SavesNewSmtpServerDetails()
        {
            var appConfigXml =
                new XElement("configuration",
                             new XElement("system.net",
                                          new XElement("mailSettings",
                                                       new XElement("smtp", new XAttribute("deliveryMethod", "Network"),
                                                                    new XElement("network", new XAttribute("defaultCredentials", "true")))))
                            ).ToString(SaveOptions.None);

            var doc = new XmlDocument();
            doc.LoadXml(appConfigXml);

            ConfigurationUtility.UpdateSmtpSettings(doc, "smtp.google.com");

            var result = XElement.Parse(doc.InnerXml);

            var smtp = result.Descendants("smtp").Single();
            var network = smtp.Element("network");

            Assert.Equal("smtp.google.com", (string) network.Attribute("host"));
        }
    }
}