using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    interface IXsdObjectVisitor
    {
        void Visit(XmlSchemaObject obj);
        void BeginChildren();
        void EndChildren();
        bool IsCircular(XmlSchemaObject obj);
    }
}