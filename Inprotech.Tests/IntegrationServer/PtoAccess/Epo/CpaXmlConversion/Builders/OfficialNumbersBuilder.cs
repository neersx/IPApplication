using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders
{
    internal class OfficialNumbersBuilder : IBuilder<XElement>
    {
        readonly XElement _baseElement;

        public OfficialNumbersBuilder(XName name)
        {
            _baseElement = new XElement(name);
        }

        public XElement Build()
        {
            return _baseElement;
        }

        public OfficialNumbersBuilder WithApplicationNumber(string gazetteNum = null, string country = null, string docNum = null, string date = null)
        {
            Helper.AddAttribute(_baseElement, "change-gazette-num", gazetteNum);

            var child = new XElement(ElementNames.DocumentId);
            Helper.AddElement(child, ElementNames.Country, country);
            Helper.AddElement(child, ElementNames.DocNumber, docNum);
            Helper.AddElement(child, ElementNames.Date, date);

            _baseElement.Add(child);

            return this;
        }

        public OfficialNumbersBuilder WithPublicationNumber(string gazetteNum = null, string lang = null, string country = null, string docNum = null, string date = null)
        {
            Helper.AddAttribute(_baseElement, "change-gazette-num", gazetteNum);

            var child = new XElement(ElementNames.DocumentId);
            Helper.AddAttribute(child, "lang", lang);

            Helper.AddElement(child, ElementNames.Country, country);
            Helper.AddElement(child, ElementNames.DocNumber, docNum);
            Helper.AddElement(child, ElementNames.Date, date);
            Helper.AddElement(child, ElementNames.Kind, "A1");

            _baseElement.Add(child);

            return this;
        }
    }
}