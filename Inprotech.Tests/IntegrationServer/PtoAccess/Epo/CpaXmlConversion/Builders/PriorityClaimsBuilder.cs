using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders
{
    internal class PriorityClaimsBuilder : IBuilder<XElement>
    {
        readonly XElement _baseElement;

        public PriorityClaimsBuilder()
        {
            _baseElement = new XElement(ElementNames.PriorityClaim);
        }

        public XElement Build()
        {
            return _baseElement;
        }

        public PriorityClaimsBuilder WithClaimDetails(string country = null, string docNum = null, string date = null, string kind = null, string seq = null)
        {
            Helper.AddAttribute(_baseElement, "sequence", seq);
            Helper.AddAttribute(_baseElement, "kind", kind);

            Helper.AddElement(_baseElement, ElementNames.Country, country);
            Helper.AddElement(_baseElement, ElementNames.DocNumber, docNum);
            Helper.AddElement(_baseElement, ElementNames.Date, date);

            return this;
        }
    }
}