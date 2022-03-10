using System.Xml.Schema;
using Inprotech.Integration.SchemaMapping.Xsd.Data;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    interface IXsdTreeBuilder
    {
        XsdTree Build(XmlSchema xmlSchema, string rootNode);
    }

    class XsdTreeBuilder : IXsdTreeBuilder
    {
        public XsdTree Build(XmlSchema xmlSchema, string rootNode)
        {
            var manager = new XsdManager(xmlSchema, rootNode);
            new SupportedXsdFeatures(manager).Validate();

            var builder = new XsdNodeBuilder();
            new XsdTraversal(manager).Traverse(builder);

            var root = builder.GetResult();

            new XsdTreeValidator().Validate(root);

            var typeBuilder = new XsdTypeBuilder();
            var types = typeBuilder.Build(manager.GetAllTypes());

            return new XsdTree
            {
                Structure = root,
                Types = types
            };
        }
    }
}