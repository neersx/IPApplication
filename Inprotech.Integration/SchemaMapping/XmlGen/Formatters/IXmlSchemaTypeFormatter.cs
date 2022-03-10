using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.XmlGen.Formatters
{
    public interface IXmlSchemaTypeFormatter
    {
        bool Supports(XmlSchemaType type, object value);
        object Format(object value);
    }
}