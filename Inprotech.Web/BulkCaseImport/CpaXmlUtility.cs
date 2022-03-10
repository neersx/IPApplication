using System;
using System.Linq;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using CPAXML;

namespace Inprotech.Web.BulkCaseImport
{
    public class NameDetails : object
    {
        public string NameCode { get; set; }
        public int NameSequence { get; set; }
    }

    public static class CpaXmlUtility
    {
        const string CpaXmLnamespace = "http://www.cpasoftwaresolutions.com";

        public static XNamespace ExtractNamespace(XDocument document)
        {
            if (document.Root == null)
                return XNamespace.None;

            var dns = document.Root.GetDefaultNamespace();
            if (dns == XNamespace.None || StringComparer.CurrentCultureIgnoreCase.Compare(dns.NamespaceName, CpaXmLnamespace) == 0)
                return dns;

            return XNamespace.None;
        }

        public static string RemoveNamespace(string xmlContent, XNamespace cpaXmlNs)
        {
            if (cpaXmlNs == XNamespace.None)
                return xmlContent;

            const string rootNodeText = "Transaction";
            var rootNodeTextPattern = string.Format("<{0}.*{1}.*>", rootNodeText, cpaXmlNs);
            var rootNodeTextPlain = string.Format("<{0}>", rootNodeText);

            return Regex.Replace(xmlContent, rootNodeTextPattern, rootNodeTextPlain, RegexOptions.IgnoreCase);
        }

        public static void CreateShortTitle(this CaseDetails caseDetails, string title)
        {
            if (string.IsNullOrWhiteSpace(title))
                return;

            caseDetails.CreateDescriptionDetails("Short Title", title);
        }

        public static void CreateOfficialNumber(
            this CaseDetails caseDetails,
            string numberType,
            string number,
            string eventCode,
            string date)
        {
            if (!string.IsNullOrWhiteSpace(number))
                caseDetails.CreateIdentifierNumberDetails(numberType, number);

            caseDetails.CreateEvent(eventCode, date);
        }

        public static void CreateNumber(this CaseDetails caseDetails, string numberType, object oNumber)
        {
            var number = oNumber?.ToString();
            if (string.IsNullOrWhiteSpace(number) || string.IsNullOrWhiteSpace(numberType))
                return;

            caseDetails.CreateIdentifierNumberDetails(numberType, number);
        }

        public static void CreateEvent(this CaseDetails caseDetails, string eventCode, object oDate)
        {
            var date = oDate?.ToString();
            if (string.IsNullOrWhiteSpace(date) || string.IsNullOrWhiteSpace(eventCode)) 
                return;

            var eventDetails = caseDetails.CreateEventDetails(eventCode);
            eventDetails.EventDate = date;
        }

        public static void CreateName(this CaseDetails caseDetails, string nameType, string orgOrLastName, string givenName, string nameCode, string nameReference = null)
        {
            if (string.IsNullOrWhiteSpace(orgOrLastName) && string.IsNullOrWhiteSpace(nameCode))
                return;

            var nameDetails = caseDetails.CreateNameDetails(nameType);
            nameDetails.NameReference = nameReference;

            var isIndividual = !string.IsNullOrWhiteSpace(givenName);

            if (isIndividual)
            {
                var formattedName = nameDetails.CreateFormattedName();
                formattedName.LastName = orgOrLastName;
                formattedName.FirstName = givenName;
            }
            else if (!string.IsNullOrWhiteSpace(orgOrLastName))
            {
                nameDetails.CreateAddressBookForOrganizationName(orgOrLastName);
            }
            else
            {
                nameDetails.CreateEmptyName();
            }

            var name = nameDetails.AddressBook.
                                   FormattedNameAddress.
                                   Name;

            name.ReceiverNameIdentifier = nameCode;
        }

        public static void CreateName(this CaseDetails caseDetails, string nameType, object nameDetails)
        {
            var details = (NameDetails)nameDetails;
            if(string.IsNullOrWhiteSpace(nameType) || string.IsNullOrWhiteSpace(details.NameCode))
                return;

            var newNameDetail = caseDetails.CreateNameDetails(nameType);
            newNameDetail.NameSequenceNumber = details.NameSequence;
            newNameDetail.CreateEmptyName();

            var name = newNameDetail.AddressBook.
                                   FormattedNameAddress.
                                   Name;

            name.ReceiverNameIdentifier = details.NameCode;
        }

        public static void CreateRelatedCase(
            this CaseDetails caseDetails,
            string relationship,
            string country,
            string numberType,
            string officialNumber,
            string eventCode,
            string eventDate)
        {
            if (string.IsNullOrWhiteSpace(relationship))
                return;

            var hasCountry = !string.IsNullOrWhiteSpace(country);
            var hasOfficialNumber = !string.IsNullOrWhiteSpace(officialNumber);
            var hasEvent = !string.IsNullOrWhiteSpace(eventDate);

            if (!hasCountry && !hasOfficialNumber && !hasEvent)
                return;

            var associatedDetails = caseDetails.CreateAssociatedCaseDetails(relationship);
            associatedDetails.AssociatedCaseCountryCode = country;

            if (hasOfficialNumber)
                associatedDetails.CreateIdentifierNumberDetails(numberType, officialNumber);

            if (!hasEvent) return;

            var eventDetails = associatedDetails.CreateEventDetails(eventCode);
            eventDetails.EventDate = eventDate;
        }

        public static void CreateDesignatedCountries(this CaseDetails caseDetails, string[] designatedCountryCodes)
        {
            if (!designatedCountryCodes.Any()) return;

            caseDetails.DesignatedCountryDetails = new DesignatedCountryDetails();
            caseDetails.DesignatedCountryDetails.DesignatedCountryCode.AddRange(designatedCountryCodes);
        }

        public static void CreateText(this CaseDetails caseDetails, string textType, object oText)
        {
            var text = oText?.ToString();
            if (!string.IsNullOrWhiteSpace(textType) && !string.IsNullOrWhiteSpace(text))
                caseDetails.CreateDescriptionDetails(textType, text);
        }
    }
}