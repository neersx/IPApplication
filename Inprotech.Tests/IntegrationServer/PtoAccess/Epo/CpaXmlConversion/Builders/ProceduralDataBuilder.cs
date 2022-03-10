using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders
{
    public class ProceduralDataBuilder : IBuilder<XElement>
    {
        readonly XElement _baseElement;

        public ProceduralDataBuilder()
        {
            _baseElement = new XElement(ElementNames.ProceduralStep);
        }

        public XElement Build()
        {
            return _baseElement;
        }

        public ProceduralDataBuilder WithProceedingLang(string lang)
        {
            Helper.AddElement(_baseElement, ElementNames.ProceduralStepCode, "PROL");
            var langElement = Helper.AddElement(_baseElement, ElementNames.ProceduralStepText, lang);

            Helper.AddAttribute(langElement, "step-text-type", "procedure language");

            return this;
        }

        public ProceduralDataBuilder WithStepDetails(string stepcode)
        {
            Helper.AddElement(_baseElement, ElementNames.ProceduralStepCode, stepcode);
            return this;
        }
    }
}