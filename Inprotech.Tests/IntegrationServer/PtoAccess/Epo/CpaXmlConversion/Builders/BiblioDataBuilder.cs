using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders
{
    internal class BiblioDataBuilder : IBuilder<XElement>
    {
        readonly XElement _baseElement;
        object[] _attributes;
        List<XElement> _children;

        public BiblioDataBuilder()
        {
            _baseElement = new XElement(ElementNames.BibliographicData);
        }

        public XElement Build()
        {
            if (_attributes != null && _baseElement != null)
            {
                _baseElement.Add(_attributes);
            }

            if (_children != null && _baseElement != null)
                // ReSharper disable once CoVariantArrayConversion
            {
                _baseElement.Add(_children.ToArray());
            }

            return _baseElement;
        }

        public BiblioDataBuilder WithBasicdata(string country, string lang, string status)
        {
            _attributes = new object[3];
            _attributes[0] = new XAttribute("country", country);
            _attributes[1] = new XAttribute("lang", lang);
            _attributes[2] = new XAttribute("status", status);

            return this;
        }

        public BiblioDataBuilder WithBasicDefaultdata()
        {
            return WithBasicdata("EP", "en", "status");
        }

        public BiblioDataBuilder WithChildElement(XElement child)
        {
            if (_children == null)
            {
                _children = new List<XElement>();
            }

            _children.Add(child);

            return this;
        }

        public BiblioDataBuilder WithParties(XElement parties)
        {
            var partiesBaseElement = _baseElement.Descendants(ElementNames.Parties).FirstOrDefault() ?? Helper.AddElement(_baseElement, ElementNames.Parties);
            if (parties != null)
            {
                partiesBaseElement.Add(parties);
            }

            return this;
        }

        public BiblioDataBuilder WithClaims(XElement[] claims, string gazetteNum = null)
        {
            var claimsBaseElement = Helper.AddElement(_baseElement, ElementNames.PriorityClaims);
            Helper.AddAttribute(claimsBaseElement, "change-gazette-num", gazetteNum);
            if (claims != null && claims.Any())
            {
                foreach (var claim in claims) claimsBaseElement.Add(claim);
            }

            return this;
        }
    }
}