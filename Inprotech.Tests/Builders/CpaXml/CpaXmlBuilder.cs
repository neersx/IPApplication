using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.Builders.CpaXml
{
    public class CpaXmlBuilder : IBuilder<XElement>
    {
        string _ = string.Empty;

        public CpaXmlBuilder()
        {
            Ns = "http://www.cpasoftwaresolutions.com";
        }

        public XNamespace Ns { get; private set; }

        public XElement CaseDetails { get; set; }

        public XElement Build()
        {
            var header = new XElement(
                                      Ns + "TransactionHeader",
                                      new XElement(
                                                   Ns + "SenderDetails"
                                                  ));

            var body = new XElement(Ns + "TransactionBody",
                                    new XElement(Ns + "TransactionContentDetails",
                                                 new XElement(Ns + "TransactionData", CaseDetails)));

            return Ns != XNamespace.None
                ? new XElement(new XElement(Ns + "Transaction", new XAttribute("xmlns", Ns), header, body))
                : new XElement(new XElement(Ns + "Transaction", header, body));
        }

        public CpaXmlBuilder WithoutNamespace()
        {
            Ns = XNamespace.None;
            return this;
        }
    }
}