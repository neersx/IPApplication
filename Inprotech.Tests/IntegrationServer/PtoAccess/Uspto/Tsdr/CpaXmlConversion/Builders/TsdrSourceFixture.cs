using System.IO;
using System.Xml;
using System.Xml.Linq;
using System.Xml.XPath;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders
{
    public class TsdrSourceFixture
    {
        public XmlNamespaceManager Resolver { get; private set; }

        public XPathNavigator Navigator { get; private set; }

        public XPathNavigator Trademark { get; private set; }

        public XmlNamespaceManager BuildResolver(XPathNavigator navigator)
        {
            var resolver = new XmlNamespaceManager(navigator.NameTable);
            resolver.AddNamespace("ns2", Ns.Trademark.ToString());
            resolver.AddNamespace("ns1", Ns.Common.ToString());
            return resolver;
        }

        public XPathNavigator BuildNavigator(XElement tsdrSource)
        {
            var reader = new StringReader(tsdrSource.ToString());
            return new XPathDocument(reader).CreateNavigator();
        }

        public TsdrSourceFixture With(XElement source)
        {
            Navigator = BuildNavigator(source);
            Resolver = BuildResolver(Navigator);
            Trademark = Navigator.SelectSingleNode("//ns2:Trademark", Resolver);
            return this;
        }
    }
}