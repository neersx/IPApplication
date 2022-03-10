using System.Xml;
using System.Xml.XPath;
using CPAXML;
using CPAXML.Extensions;
using Inprotech.IntegrationServer.PtoAccess.Utilities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public interface IEventsConverter
    {
        void Convert(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails);
    }

    public class EventsConverter : IEventsConverter
    {
        
        public void Convert(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails)
        {
            var markEventNodes = trademarkNode.Select("ns2:MarkEventBag/ns2:MarkEvent", resolver);
            while (markEventNodes.MoveNext())
            {
                var current = markEventNodes.Current;
                var eventDate = XmlTools.GetXmlNodeDateValue(current, "ns2:MarkEventDate", resolver);
                var eventCode = XmlTools.GetXmlNodeValue(current, "ns2:NationalMarkEvent/ns2:MarkEventCode", resolver);
                var eventComment = XmlTools.GetXmlNodeValue(current, "ns2:MarkEventCategory", resolver);
                var eventDescription = XmlTools.GetXmlNodeValue(current,
                    "ns2:NationalMarkEvent/ns2:MarkEventDescriptionText", resolver);
                if (string.IsNullOrEmpty(eventCode)) continue;
                var eventDetails = caseDetails.CreateEventDetails(eventCode);
                if (eventDate.HasValue)
                {
                    eventDetails.EventDate = eventDate.Iso8601OrNull();
                }
                eventDetails.EventDescription = eventDescription;
                eventDetails.EventText = eventComment;
            }
        }
    }
}