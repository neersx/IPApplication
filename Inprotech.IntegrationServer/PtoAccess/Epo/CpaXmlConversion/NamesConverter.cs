using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public interface INamesConverter
    {
        void Convert(bibliographicdata bibliographicdata, CaseDetails caseDetails);
    }

    public class NamesConverter : INamesConverter
    {
        public void Convert(bibliographicdata bibliographicdata, CaseDetails caseDetails)
        {
            var applicants = ExtractApplicants(bibliographicdata);
            if (applicants != null)
            {
                foreach (var applicant in applicants)
                {
                    var name = applicant.addressbook
                        .SelectMany(i => i.Items)
                        .Where(i => i is name)
                        .OfType<name>()
                        .SingleOrDefault();

                    if (name == null || name.Text == null)
                        continue;

                    ExtractNameAddressForApplicant(applicant, name, caseDetails);
                }
            }

            var inventors = ExtractInventors(bibliographicdata);
            if (inventors == null)
                return;

            foreach (var inventor in inventors)
            {
                var name = inventor.addressbook
                   .SelectMany(i => i.Items)
                   .Where(i => i is name)
                   .OfType<name>()
                    .SingleOrDefault();

                if (name == null || name.Text == null)
                    continue;

                ExtractNameAddressForInventor(inventor, name, caseDetails);
            }
        }

        static IEnumerable<applicant> ExtractApplicants(bibliographicdata bibliographicdata)
        {
            if (bibliographicdata.parties == null)
                return null;

            return bibliographicdata.parties.applicants
                    .LatestByChangeGazetteNum(i => i.changegazettenum)
                    .SelectMany(i => i.applicant);
        }

        static IEnumerable<inventor> ExtractInventors(bibliographicdata bibliographicdata)
        {
            if (bibliographicdata.parties == null)
                return null;

            return bibliographicdata.parties.inventors
                     .LatestByChangeGazetteNum(i => i.changegazettenum)
                     .SelectMany(inv => inv.Items)
                     .Where(inv => inv is inventor)
                     .OfType<inventor>();
        }

        static void InsertAddressBook(NameDetails nameDetails, string name, FormattedAddress formattedAddress)
        {
            if (string.IsNullOrEmpty(name))
                return;

            var addressBook = new AddressBook
            {
                FormattedNameAddress = new FormattedNameAddress()
            };
            nameDetails.AddressBook = addressBook;
            var freeFormatName = new FreeFormatName();
            addressBook.FormattedNameAddress.Name.FreeFormatName = freeFormatName;
            freeFormatName.FreeFormatNameDetails = new FreeFormatNameDetails();
            freeFormatName.FreeFormatNameDetails.FreeFormatNameLine.Add(name);
            if (formattedAddress == null)
                return;

            addressBook.FormattedNameAddress.Address = new Address {FormattedAddress = formattedAddress};
        }

        static void ExtractNameAddressForApplicant(applicant applicant, name name, CaseDetails caseDetails)
        {
            var details = caseDetails.CreateNameDetails("Applicant");
            details.NameSequenceNumber = int.Parse(applicant.sequence);
            FormattedAddress formattedAddress = null;

            var addressItems = applicant.addressbook
                .SelectMany(i => i.Items)
                .Where(i => i is address)
                .OfType<address>()
                .SelectMany(a => a.Items)
                .ToArray();

            if (addressItems.Any())
                formattedAddress = ExtractAddress(addressItems.ToList());

            InsertAddressBook(details, name.Text.FirstOrDefault(), formattedAddress);
        }

        static void ExtractNameAddressForInventor(inventor inventor, name name, CaseDetails caseDetails)
        {
            var details = caseDetails.CreateNameDetails("Inventor");
            details.NameSequenceNumber = int.Parse(inventor.sequence);
            FormattedAddress formattedAddress = null;

            var addressItems = inventor.addressbook
                        .SelectMany(i => i.Items)
                        .Where(i => i is address)
                        .OfType<address>()
                        .SelectMany(a => a.Items)
                        .ToArray();

            if (addressItems.Any())
                formattedAddress = ExtractAddress(addressItems.ToList());

            InsertAddressBook(details, name.Text.FirstOrDefault(), formattedAddress);
        }

        static FormattedAddress ExtractAddress(IEnumerable<object> addressItems)
        {

            var addressLines = new List<string>();
            var country = String.Empty;

            foreach (var addressItem in addressItems)
            {
                var address1 = addressItem as address1;
                if (address1 != null && address1.Text != null)
                {
                    addressLines.Add(address1.Text.FirstOrDefault());
                    continue;
                }

                var address2 = addressItem as address2;
                if (address2 != null && address2.Text != null)
                {
                    addressLines.Add(address2.Text.FirstOrDefault());
                    continue;
                }

                var countryItem = addressItem as country;
                if (countryItem != null && countryItem.Text != null)
                {
                    country = countryItem.Text.FirstOrDefault();
                }
            }

            return new FormattedAddress
            {
                AddressLine = addressLines,
                AddressCountryCode = country
            };
        }
    }
}

