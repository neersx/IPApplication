using System;
using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.XmlGen.Formatters
{
    class DateTimeFormatter : IXmlSchemaTypeFormatter
    {
        public bool Supports(XmlSchemaType type, object value)
        {
            return type.TypeCode == XmlTypeCode.DateTime && value is DateTime;
        }

        public object Format(object value)
        {
            if (value == null)
                return null;

            return ((DateTime) value).ToString("s");
        }
    }
}