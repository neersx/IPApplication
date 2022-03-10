using System;
using System.Collections.Generic;
using System.Xml;
using System.Xml.XPath;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Utilities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public interface IApplicantsConverter
    {
        void Convert(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails);
    }

    public class ApplicantsConverter : IApplicantsConverter
    {
        public void Convert(XPathNavigator trademarkNode, XmlNamespaceManager resolver, CaseDetails caseDetails)
        {
            var applicantNodes = trademarkNode.Select("//ns2:Applicant[not(@ns1:sequenceNumber < preceding-sibling::ns2:Applicant/@ns1:sequenceNumber) " +
                                                            "and not (@ns1:sequenceNumber < following-sibling::ns2:Applicant/@ns1:sequenceNumber)]", resolver);

            while (applicantNodes.MoveNext())
            {
                var current = applicantNodes.Current;

                var entityName = XmlTools.GetXmlNodeValue(current, "ns1:Contact/ns1:Name/ns1:EntityName", resolver);
                var organisationName = XmlTools.GetXmlNodeValue(current,
                    "ns1:Contact/ns1:Name/ns1:OrganizationName/ns1:OrganizationStandardName", resolver);
                var personFullName = XmlTools.GetXmlNodeValue(current,
                    "ns1:Contact/ns1:Name/ns1:PersonName/ns1:PersonFullName", resolver);

                NameKindType? nameKind = string.IsNullOrWhiteSpace(personFullName)
                    ? NameKindType.Organisation
                    : NameKindType.Individual;

                var nameDetails = caseDetails.CreateNameDetails("Applicant");
                var addressBook = new AddressBook {FormattedNameAddress = new FormattedNameAddress()};
                nameDetails.AddressBook = addressBook;
                var freeFormatName = new FreeFormatName {NameKind = nameKind};
                addressBook.FormattedNameAddress.Name.FreeFormatName = freeFormatName;
                freeFormatName.FreeFormatNameDetails = new FreeFormatNameDetails
                                                       {
                                                           FreeFormatNameLine = new List<string>(new[]
                                                                                                 {
                                                                                                     personFullName ??
                                                                                                     organisationName ??
                                                                                                     entityName
                                                                                                 })
                                                       };

                var formattedAddressNode =
                    current.SelectSingleNode(
                        "ns1:Contact/ns1:PostalAddressBag/ns1:PostalAddress/ns1:PostalStructuredAddress",
                        resolver);
                if (formattedAddressNode == null) continue;

                var address = new Address();
                addressBook.FormattedNameAddress.Address = address;
                address.FormattedAddress = new FormattedAddress
                                           {
                                               AddressStreet =
                                                   string.Join(Environment.NewLine,
                                                       BuildAddressLines(formattedAddressNode, resolver)),
                                               AddressCity =
                                                   XmlTools.GetXmlNodeValue(formattedAddressNode,
                                                       "ns1:CityName",
                                                       resolver),
                                               AddressState =
                                                   XmlTools.GetXmlNodeValue(formattedAddressNode,
                                                       "ns1:GeographicRegionName",
                                                       resolver),
                                               AddressPostcode =
                                                   XmlTools.GetXmlNodeValue(formattedAddressNode,
                                                       "ns1:PostalCode",
                                                       resolver),
                                               AddressCountryCode =
                                                   XmlTools.GetXmlNodeValue(formattedAddressNode,
                                                       "ns1:CountryCode", resolver)
                                           };
            }
        }

        static IEnumerable<string> BuildAddressLines(XPathNavigator formattedAddressNode, XmlNamespaceManager resolver)
        {
            var addressLineNodes = formattedAddressNode.Select("ns1:AddressLineText", resolver);
            while (addressLineNodes.MoveNext())
            {
                var addressLine = addressLineNodes.Current;
                if (string.IsNullOrWhiteSpace(addressLine.Value)) continue;

                yield return addressLine.Value;
            }
        }
    }
}