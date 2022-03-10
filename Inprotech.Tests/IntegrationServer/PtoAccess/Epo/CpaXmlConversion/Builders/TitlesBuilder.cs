using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders
{
    internal class TitlesBuilder : IBuilder<XElement>
    {
        readonly XElement _baseElement;

        public TitlesBuilder()
        {
            _baseElement = new XElement(ElementNames.InventionTitle);
        }

        public XElement Build()
        {
            return _baseElement;
        }

        public TitlesBuilder WithDetails(string gazetteNum, string lang, string title)
        {
            Helper.AddAttribute(_baseElement, "change-gazette-num", gazetteNum);
            Helper.AddAttribute(_baseElement, "lang", lang);

            _baseElement.SetValue(title);

            return this;
        }
    }
}