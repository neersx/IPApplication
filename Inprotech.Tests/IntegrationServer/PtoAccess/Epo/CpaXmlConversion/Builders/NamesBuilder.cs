using System.Xml.Linq;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders
{
    internal class NamesBuilder
    {
        readonly XElement _baseElement;

        public NamesBuilder(XName name)
        {
            _baseElement = new XElement(name);
        }

        public XElement Build()
        {
            return _baseElement;
        }

        public NamesBuilder WithApplicantDetails(string gazetteNum = null, string name = null, string designation = null, string seq = null, bool withAddress = false, string country = null)
        {
            Helper.AddAttribute(_baseElement, "change-gazette-num", gazetteNum);

            var child = Helper.AddElement(_baseElement, ElementNames.Applicant);
            Helper.AddAttribute(child, "app-type", "applicant");
            Helper.AddAttribute(child, "designation", designation);
            Helper.AddAttribute(child, "sequence", seq);

            var addressBook = Helper.AddElement(child, ElementNames.AddressBook);
            Helper.AddElement(addressBook, ElementNames.Name, name);
            if (withAddress)
            {
                WithAddress(addressBook, country);
            }

            return this;
        }

        public NamesBuilder WithInventorDetails(string gazetteNum = null, string name = null, string seq = null, bool withAddress = false, string country = null)
        {
            Helper.AddAttribute(_baseElement, "change-gazette-num", gazetteNum);

            var child = Helper.AddElement(_baseElement, ElementNames.Inventor);
            Helper.AddAttribute(child, "sequence", seq);

            var addressBook = Helper.AddElement(child, ElementNames.AddressBook);
            Helper.AddElement(addressBook, ElementNames.Name, name);
            if (withAddress)
            {
                WithAddress(addressBook, country);
            }

            return this;
        }

        public void WithAddress(XElement addressBookElement, string country)
        {
            var address = Helper.AddElement(addressBookElement, ElementNames.Address);
            Helper.AddElement(address, ElementNames.Address1, "Address line 1");
            Helper.AddElement(address, ElementNames.Address2, "Address line 2");
            Helper.AddElement(address, ElementNames.Country, country);
        }
    }
}