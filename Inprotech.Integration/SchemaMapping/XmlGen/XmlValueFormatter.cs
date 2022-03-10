using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Schema;
using Inprotech.Integration.SchemaMapping.XmlGen.Formatters;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using Attribute = Inprotech.Integration.SchemaMapping.Xsd.Data.Attribute;

namespace Inprotech.Integration.SchemaMapping.XmlGen
{
    public interface IXmlValueFormatter
    {
        object Format(XsdNode xsdNode, object value, string selectedUnionType);
    }

    class XmlValueFormatter : IXmlValueFormatter
    {
        readonly IEnumerable<IXmlSchemaTypeFormatter> _formatters;

        public XmlValueFormatter(IEnumerable<IXmlSchemaTypeFormatter> formatters)
        {
            _formatters = formatters;
        }

        public object Format(XsdNode xsdNode, object value, string selectedUnionType)
        {
            if (xsdNode == null) throw new ArgumentNullException(nameof(xsdNode));

            XmlSchemaType type;

            if (xsdNode is Attribute)
                type = ((Attribute)xsdNode).XmlSchemaType;
            else if (xsdNode is Element)
                type = ((Element)xsdNode).XmlSchemaType;
            else
                return value;

            if (type is XmlSchemaSimpleType simpleType)
            {
                if (simpleType.Content is XmlSchemaSimpleTypeUnion union && !string.IsNullOrEmpty(selectedUnionType))
                {
                    var memberType = union.BaseMemberTypes.FirstOrDefault(_ => _.Name == selectedUnionType);
                    if (memberType != null)
                        return FormatValue(memberType, value);
                }
            }

            return FormatValue(type, value);
        }

        object FormatValue(XmlSchemaType type, object value)
        {
            foreach (var formatter in _formatters)
            {
                if (formatter.Supports(type, value))
                {
                    return formatter.Format(value);
                }
            }

            return value;
        }
    }
}