using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using CPAXML;

namespace Inprotech.Tests.IntegrationServer.PtoAccess
{
    public static class XElementExt
    {
        static readonly XNamespace CpaxmlNs = "http://www.cpasoftwaresolutions.com";

        public static string GetCpaXmlNumber(this XElement caseDetails, string name)
        {
            return (string) caseDetails.Elements(CpaxmlNs + "IdentifierNumberDetails")
                                       .Single(_ => (string) _.Element(CpaxmlNs + "IdentifierNumberCode") == name)
                                       .Element(CpaxmlNs + "IdentifierNumberText");
        }

        public static string GetCpaXmlDate(this XElement caseDetails, string name)
        {
            return (string) caseDetails.Elements(CpaxmlNs + "EventDetails")
                                       .SingleOrDefault(_ => (string) _.Element(CpaxmlNs + "EventCode") == name)
                                       ?
                                       .Element(CpaxmlNs + "EventDate");
        }

        public static string GetCpaXmlEvent(this XElement caseDetails, string name, string elementName)
        {
            return (string) caseDetails.Elements(CpaxmlNs + "EventDetails")
                                       .SingleOrDefault(_ => (string) _.Element(CpaxmlNs + "EventCode") == name)
                                       ?.Element(CpaxmlNs + elementName);
        }

        public static IEnumerable<string> GetCpaXmlFreeFormatNames(this XElement caseDetails, string type)
        {
            foreach (var name in caseDetails.Elements(CpaxmlNs + "NameDetails"))
            {
                var details = name.Element(CpaxmlNs + "AddressBook")
                                  ?.Element(CpaxmlNs + "FormattedNameAddress")
                                  ?.Element(CpaxmlNs + "Name")
                                  ?.Element(CpaxmlNs + "FreeFormatName")
                                  ?.Element(CpaxmlNs + "FreeFormatNameDetails");

                if (details == null) continue;

                yield return (string) details.Element(CpaxmlNs + "FreeFormatNameLine");
            }
        }

        public static IEnumerable<AssociatedCaseDetails> ParseAssociatedCaseDetails(this XElement caseDetails)
        {
            return caseDetails.Elements(CpaxmlNs + "AssociatedCaseDetails")
                              .Select(_ => new AssociatedCaseDetails((string) _.Element(CpaxmlNs + "AssociatedCaseRelationshipCode"))
                              {
                                  AssociatedCaseStatus = (string) _.Element(CpaxmlNs + "AssociatedCaseStatus"),
                                  AssociatedCaseComment = (string) _.Element(CpaxmlNs + "AssociatedCaseComment"),
                                  AssociatedCaseCountryCode = (string) _.Element(CpaxmlNs + "AssociatedCaseCountryCode"),
                                  AssociatedCaseIdentifierNumberDetails = _.Elements(CpaxmlNs + "AssociatedCaseIdentifierNumberDetails")
                                                                           .Select(FromAssociatedCaseIdentifierNumberDetails)
                                                                           .ToList(),
                                  AssociatedCaseEventDetails = _.Elements(CpaxmlNs + "AssociatedCaseEventDetails")
                                                                .Select(FromAssociatedCaseEventDetails)
                                                                .ToList()
                              });
        }

        static IdentifierNumberDetails FromAssociatedCaseIdentifierNumberDetails(XElement identifierNumberDetails)
        {
            return new IdentifierNumberDetails(
                                               (string) identifierNumberDetails.Element(CpaxmlNs + "IdentifierNumberCode"),
                                               (string) identifierNumberDetails.Element(CpaxmlNs + "IdentifierNumberText"));
        }

        static EventDetails FromAssociatedCaseEventDetails(XElement eventDetails)
        {
            return new EventDetails((string) eventDetails.Element(CpaxmlNs + "EventCode"))
            {
                EventDate = (string) eventDetails.Element(CpaxmlNs + "EventDate")
            };
        }
    }

    public static class AssociatedCaseDetailsExt
    {
        public static string GetCpaXmlNumber(this IEnumerable<IdentifierNumberDetails> identifierNumberDetails, string code)
        {
            return identifierNumberDetails?.SingleOrDefault(_ => _.IdentifierNumberCode == code)?.IdentifierNumberText;
        }

        public static string GetCpaXmlDate(this IEnumerable<EventDetails> eventDetails, string code)
        {
            return eventDetails?.SingleOrDefault(_ => _.EventCode == code)?.EventDate;
        }
    }
}