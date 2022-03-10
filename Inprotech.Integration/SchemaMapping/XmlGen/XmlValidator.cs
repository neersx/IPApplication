using System.Text;
using System.Xml.Linq;
using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.XmlGen
{
    interface IXmlValidator
    {
        bool Validate(XmlSchemaSet xmlSchemaSet, XDocument doc, out string errorMessage);
    }

    class XmlValidator : IXmlValidator
    {
        public bool Validate(XmlSchemaSet xmlSchemaSet, XDocument doc, out string errorMessage)
        {
            var sbuf = new StringBuilder();
            var hasErrors = false;

            doc.Validate(xmlSchemaSet, (o, e) =>
            {
                sbuf.AppendLine(e.Message);
                hasErrors = true;
            });

            errorMessage = sbuf.ToString();

            return !hasErrors;
        }
    }
}
