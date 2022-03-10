using System.Xml;
using System.Xml.XPath;
using CPAXML;
using CPAXML.Extensions;
using Inprotech.IntegrationServer.PtoAccess.Utilities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public interface IOtherCriticalDetailsConverter
    {
        void Convert(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails);
    }

    public class OtherCriticalDetailsConverter : IOtherCriticalDetailsConverter
    {

        public void Convert(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails)
        {
            ExtractMarkCurrentStatus(trademarkNode, resolver, caseDetails);

            ExtractMarkProperties(trademarkNode, resolver, caseDetails);

            ExtractDescriptionAndShortTitle(trademarkNode, resolver, caseDetails);
        }

        static void ExtractMarkProperties(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails)
        {
            var markDisclaimer = XmlTools.GetXmlNodeValue(trademarkNode,
                "ns2:MarkDisclaimerBag/ns2:MarkDisclaimerText", resolver);
            if (string.IsNullOrEmpty(markDisclaimer)) return;

            caseDetails.CreateDescriptionDetails("Disclaimer", markDisclaimer);
        }

        static void ExtractDescriptionAndShortTitle(XPathNavigator trademarkNode, XmlNamespaceManager resolver,
            CaseDetails caseDetails)
        {
            var markRepresentationNode = trademarkNode.SelectSingleNode("ns2:MarkRepresentation", resolver);
            if (markRepresentationNode == null) return;
            
            var markDescription = XmlTools.GetXmlNodeValue(markRepresentationNode,
                "ns2:MarkDescriptionBag/ns2:MarkDescriptionText", resolver);
            if (!string.IsNullOrWhiteSpace(markDescription))
                caseDetails.CreateDescriptionDetails("Mark Description", markDescription);

            var markVerbalElementText = XmlTools.GetXmlNodeValue(markRepresentationNode,
                "ns2:MarkReproduction/ns2:WordMarkSpecification/ns2:MarkVerbalElementText", resolver);
            if (!string.IsNullOrWhiteSpace(markVerbalElementText))
                caseDetails.CreateDescriptionDetails("Short Title", markVerbalElementText);
        }

        static void ExtractMarkCurrentStatus(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails)
        {
            var statusCode = XmlTools.GetXmlNodeValue(trademarkNode, "ns2:MarkCurrentStatusCode", resolver);
            var statusDescription = XmlTools.GetXmlNodeValue(trademarkNode, "ns2:NationalTrademarkInformation/ns2:MarkCurrentStatusExternalDescriptionText", resolver);
            var statusDate = XmlTools.GetXmlNodeDateValue(trademarkNode, "ns2:MarkCurrentStatusDate", resolver);

            if (string.IsNullOrWhiteSpace(statusCode) && string.IsNullOrWhiteSpace(statusDescription)) return;

            var status = !string.IsNullOrWhiteSpace(statusCode) && !string.IsNullOrWhiteSpace(statusDescription)
                ? statusCode + " - " + statusDescription
                : !string.IsNullOrWhiteSpace(statusCode) ? statusCode : statusDescription;

            var eventDetails = caseDetails.CreateEventDetails("Status");
            eventDetails.EventText = caseDetails.CaseStatus = status;

            if (!statusDate.HasValue) return;
            eventDetails.EventDate = statusDate.Iso8601OrNull();
        }
    }
}