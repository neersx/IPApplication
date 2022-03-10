using System.Xml.Linq;
using Inprotech.Web.BulkCaseImport.Validators;
using InprotechKaizen.Model.Ede;

namespace Inprotech.Tests.Web.Builders.BulkCaseImport
{
    public class CpaXmlBuilder : IBuilder<XDocument>
    {
        string _ = string.Empty;

        public CpaXmlBuilder()
        {
            Ns = "http://www.cpasoftwaresolutions.com";

            SenderDetailsFixture = new SenderDetails
            {
                RequestType = KnownSenderRequestTypes.CaseImport,
                RequestIdentifier = "12136513",
                Sender = "MYAC",
                SenderFileName = "abc.xml"
            };
        }

        public XNamespace Ns { get; private set; }

        public SenderDetails SenderDetailsFixture { get; private set; }

        public XDocument Build()
        {
            var body = new XElement(
                                    Ns + "TransactionHeader",
                                    new XElement(
                                                 Ns + "SenderDetails",
                                                 new XElement(Ns + "Sender" + _, SenderDetailsFixture.Sender),
                                                 new XElement(Ns + "SenderRequestType" + _, SenderDetailsFixture.RequestType),
                                                 new XElement(Ns + "SenderRequestIdentifier" + _, SenderDetailsFixture.RequestIdentifier),
                                                 new XElement(Ns + "SenderFilename" + _, SenderDetailsFixture.SenderFileName))
                                   );

            return Ns != XNamespace.None ? new XDocument(new XElement(Ns + "Transaction", new XAttribute("xmlns", Ns), body)) : new XDocument(new XElement(Ns + "Transaction", body));
        }

        public CpaXmlBuilder WithSenderDetails(SenderDetails senderDetails)
        {
            SenderDetailsFixture = senderDetails;
            return this;
        }

        public CpaXmlBuilder WithoutNamespace()
        {
            Ns = XNamespace.None;
            return this;
        }

        public CpaXmlBuilder WithInvalidNamespace()
        {
            Ns = "http://www.not-cpaxml.com";
            return this;
        }

        public CpaXmlBuilder WithInvalidXmlStructure()
        {
            _ = "1";
            return this;
        }
    }
}