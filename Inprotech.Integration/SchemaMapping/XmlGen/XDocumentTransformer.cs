using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Integration.SchemaMapping.Xsd.Data;

namespace Inprotech.Integration.SchemaMapping.XmlGen
{
    interface IXDocumentTransformer
    {
        XDocument Transform(XmlGenNode node);
    }

    class XDocumentTransformer : IXDocumentTransformer
    {
        public XDocument Transform(XmlGenNode node)
        {
            if (node == null) throw new ArgumentNullException("node");

            var body = TransformInternal(node);

            if (body == null)
                throw XmlGenExceptionHelper.NoXmlElementGenerated();

            return new XDocument(
                new XDeclaration("1.0", "utf-8", "yes"),
                body);
        }

        XElement TransformInternal(XmlGenNode node)
        {
            var value = node.GetValue();
            var children = new List<XElement>();
            var attributes = new List<XAttribute>();

            foreach (var child in node.Children)
            {
                if (child.IsAttribute)
                {
                    var attr = TransformAttribute(child);
                    if (attr != null)
                        attributes.Add(attr);
                }
                else
                {
                    var elm = TransformInternal(child);
                    if (elm != null)
                    {
                        if (child.XsdNode is Choice || child.XsdNode is Sequence)
                        {
                            children.AddRange(elm.Elements());
                        }
                        else
                        {
                            children.Add(elm);
                        }
                    }
                }
            }

            if(value == null && !children.Any() && !attributes.Any())
                return null;

            XNamespace xmlns = node.Namespace;
            var r = new XElement(xmlns + node.Name);

            if ((node.XsdNode as Element)?.IsEmpty == true)
            {
                if (Boolean.TryParse(Convert.ToString(value), out bool include) && !include)
                    return null;
                value = null;
            }

            if (value != null)
                r.Add(value);

            if(children.Any())
                r.Add(children);

            if (attributes.Any())
                r.Add(attributes);

            return r;
        }

        XAttribute TransformAttribute(XmlGenNode node)
        {
            var value = node.GetValue();

            if (value == null)
                return null;

            XNamespace xmlns = node.Namespace;
            return new XAttribute(xmlns + node.Name, value);
        }
    }
}