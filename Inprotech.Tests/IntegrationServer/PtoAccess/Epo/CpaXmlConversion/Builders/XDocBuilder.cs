using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders
{
    public class XDocBuilder : IBuilder<XDocument>
    {
        readonly XDocument _document;

        public XDocBuilder()
        {
            _document = new XDocument(new XDeclaration("1.0", "utf-8", "yes"),
                                      new XElement(Ns.Ops + "world-patent-data", new XAttribute(XNamespace.Xmlns + "ops", Ns.Ops),
                                                   new XAttribute(XNamespace.Xmlns + "reg", Ns.Reg),
                                                   new XAttribute(XNamespace.Xmlns + "xlink", Ns.XLink),
                                                   new XAttribute(XNamespace.Xmlns + "cpc", Ns.Cpc),
                                                   new XAttribute(XNamespace.Xmlns + "cpcdef", Ns.CpcDef)
                                                  ));
            var regSearch = new XElement(Ns.Ops + "register-search");
            var regDocs = new XElement(Ns.Reg + "register-documents");
            var regDoc = new XElement(Ns.Reg + "register-document");

            regDocs.Add(regDoc);
            regSearch.Add(regDocs);
            if (_document.Root != null)
            {
                _document.Root.Add(new XElement(regSearch));
            }
        }

        public XDocument Build()
        {
            return _document;
        }

        public XDocBuilder WithChildElement(XElement child)
        {
            if (_document.Root == null)
            {
                return this;
            }

            var registerDoc = _document.Root.Descendants(Ns.Reg + "register-document").FirstOrDefault();
            if (registerDoc != null)
                // ReSharper disable once CoVariantArrayConversion
            {
                registerDoc.Add(child);
            }

            return this;
        }

        public XDocBuilder WithProceduralData(XElement step)
        {
            if (_document.Root == null)
            {
                return this;
            }

            var registerDoc = _document.Root.Descendants(Ns.Reg + "register-document").FirstOrDefault();
            if (registerDoc == null)
            {
                return this;
            }

            var dataBaseElement = registerDoc.Descendants(ElementNames.ProceduralData).FirstOrDefault() ?? Helper.AddElement(registerDoc, ElementNames.ProceduralData);

            if (dataBaseElement != null && step != null)
            {
                dataBaseElement.Add(step);
            }

            return this;
        }
    }
}