using System.Xml;
using System.Xml.XPath;
using CPAXML;
using CPAXML.Extensions;
using Inprotech.IntegrationServer.PtoAccess.Utilities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public interface ICriticalDatesConverter
    {
        void Convert(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails);
    }

    public class CriticalDatesConverter : ICriticalDatesConverter
    {
        public void Convert(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails)
        {
            ExtractApplicationNumberAndDate(trademarkNode, resolver, caseDetails);

            ExtractRegistrationNumberAndDate(trademarkNode, resolver, caseDetails);

            ExtractPublicationDate(trademarkNode, resolver, caseDetails);

            ExtractAbandonDate(trademarkNode, resolver, caseDetails);
        }

        static void ExtractAbandonDate(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails)
        {
            var abandonDate =
                XmlTools.GetXmlNodeDateValue(trademarkNode, "ns2:NationalTrademarkInformation/ns2:ApplicationAbandonedDate",
                    resolver);

            if (!abandonDate.HasValue) return;
            var eventDetails = caseDetails.CreateEventDetails("Abandon");
            eventDetails.EventDate = abandonDate.Iso8601OrNull();
        }

        static void ExtractPublicationDate(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails)
        {
            var publicationDate = XmlTools.GetXmlNodeDateValue(trademarkNode,
                "ns2:PublicationBag/ns2:Publication/ns1:PublicationDate", resolver);
            if (!publicationDate.HasValue) return;
            var eventDetails = caseDetails.CreateEventDetails("Publication");
            eventDetails.EventDate = publicationDate.Iso8601OrNull();
        }

        static void ExtractRegistrationNumberAndDate(XPathNavigator trademarkNode, XmlNamespaceManager resolver,
            CaseDetails caseDetails)
        {
            var registrationNumber = XmlTools.GetXmlNodeValue(trademarkNode, "ns1:RegistrationNumber", resolver);
            if (!string.IsNullOrEmpty(registrationNumber))
                caseDetails.CreateIdentifierNumberDetails("Registration/Grant", registrationNumber);

            var registrationDate = XmlTools.GetXmlNodeDateValue(trademarkNode, "ns1:RegistrationDate", resolver);

            if (!registrationDate.HasValue) return;
            var eventDetails = caseDetails.CreateEventDetails("Registration/Grant");
            eventDetails.EventDate = registrationDate.Iso8601OrNull();
        }

        static void ExtractApplicationNumberAndDate(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails)
        {
            var applicationNode = trademarkNode.SelectSingleNode("ns1:ApplicationNumber", resolver);
            if (applicationNode != null)
            {
                var applicationNumber = XmlTools.GetXmlNodeValue(applicationNode, "ns1:ApplicationNumberText", resolver);
                if (!string.IsNullOrEmpty(applicationNumber))
                    caseDetails.CreateIdentifierNumberDetails("Application", applicationNumber);
            }

            var applicationDate = XmlTools.GetXmlNodeDateValue(trademarkNode, "ns2:ApplicationDate", resolver);

            if (!applicationDate.HasValue) return;
            var eventDetails = caseDetails.CreateEventDetails("Application");
            eventDetails.EventDate = applicationDate.Iso8601OrNull();
        }

    }
}