using System;
using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    [Serializable]
    internal class XsdNotSupportedException : Exception
    {
        public XsdNotSupportedException(XmlSchemaObject obj)
        {
            XmlSchemaObject = obj;
        }

        public XmlSchemaObject XmlSchemaObject { get; }
    }
}