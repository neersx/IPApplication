using System.Collections.Generic;
using System.Linq;
using System.Xml.Schema;
using Inprotech.Integration.SchemaMapping.Data;
using Inprotech.Integration.SchemaMapping.Xsd.Data;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    static class Extensions
    {
        public static bool IsBuiltIn(this XmlSchemaType type)
        {
            return XmlSchemaType.GetBuiltInSimpleType(type.QualifiedName) != null
                   || XmlSchemaType.GetBuiltInComplexType(type.QualifiedName) != null;
        }

        public static Restriction Inherit(this Restriction child, Restriction parent)
        {
            if (child == null || parent == null)
                return child;

            child.Pattern = child.Pattern ?? parent.Pattern;
            child.Length = child.Length ?? parent.Length;
            child.MinLength = child.MinLength ?? parent.MinLength;
            child.MaxLength = child.MaxLength ?? parent.MaxLength;
            child.MaxExclusive = child.MaxExclusive ?? parent.MaxExclusive;
            child.MaxInclusive = child.MaxInclusive ?? parent.MaxInclusive;
            child.MinExclusive = child.MinExclusive ?? parent.MinExclusive;
            child.MinInclusive = child.MinInclusive ?? parent.MinInclusive;
            child.TotalDigits = child.TotalDigits ?? parent.TotalDigits;

            if (parent.Enumerations != null)
                child.Enumerations = parent.Enumerations.Union(child.Enumerations ?? Enumerable.Empty<string>()).ToArray();

            return child;
        }

        public static Type Inherit(this Type child, Type parent)
        {
            if (child == null || parent == null)
                return child;

            if (parent.Restrictions == null)
                return child;

            if (child.Restrictions == null)
                child.Restrictions = new Restriction();

            child.Restrictions.Inherit(parent.Restrictions);

            return child;
        }

        public static XmlSchema RootNodeSchema(this XmlSchemaSet schemaSet, string rootNode="")
        {
            if (schemaSet == null) return null;
            var schemas = schemaSet.Schemas().OfType<XmlSchema>().ToArray();
            if (string.IsNullOrEmpty(rootNode) || schemas.Length == 1)
                return schemas.First();

            var rootObj = new RootNodeInfo().ParseJson(rootNode);
            return schemas.Single(_ => _.Items.OfType<XmlSchemaElement>().Any(p => p.QualifiedName == rootObj.QualifiedName));

        }

        public static XmlSchemaElement RootNodeElement(this XmlSchema schema, string rootNode)
        {
            if (schema.Items.OfType<XmlSchemaElement>().Count() == 1)
                return schema.Items.OfType<XmlSchemaElement>().Single();

            var rootObj = new RootNodeInfo().ParseJson(rootNode);
            return schema.Items.OfType<XmlSchemaElement>().Single(_ => _.QualifiedName == rootObj.QualifiedName);
        }

        public static IEnumerable<XmlSchemaElement> GetNestedTypes(this XmlSchemaGroupBase xmlSchemaGroupBase)
        {
            if (xmlSchemaGroupBase != null)
            {
                foreach (var xmlSchemaObject in xmlSchemaGroupBase.Items)
                {
                    var element = xmlSchemaObject as XmlSchemaElement;
                    if (element != null)
                    {
                        yield return element;
                    }
                    else
                    {
                        var group = xmlSchemaObject as XmlSchemaGroupBase;
                        if (group != null)
                            foreach (var item in group.GetNestedTypes())
                                yield return item;
                    }
                }
            }
        }
    }
}