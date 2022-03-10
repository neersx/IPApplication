using System.Collections.Generic;
using System.Linq;
using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    internal class XsdTraversal
    {
        readonly XsdManager _xsdManager;
        IXsdObjectVisitor _xsdObjectVisitor;

        public XsdTraversal(XsdManager xsdManager)
        {
            _xsdManager = xsdManager;
        }

        public void Traverse(IXsdObjectVisitor xsdObjectVisitor)
        {
            _xsdObjectVisitor = xsdObjectVisitor;

            Traverse(_xsdManager.RootElement);
        }

        void Traverse(XmlSchemaElement element)
        {
            if (element == null) return;

            var type = element.ElementSchemaType;

            if (_xsdObjectVisitor.IsCircular(element))
                return;

            _xsdObjectVisitor.Visit(element);

            if (type is XmlSchemaSimpleType)
                return;

            _xsdObjectVisitor.BeginChildren();

            var complexType = (XmlSchemaComplexType) type;

            foreach (var attribute in GetAttributes(complexType))
                _xsdObjectVisitor.Visit(attribute);

            if (!complexType.IsMixed)////To be changed when tags of Mixed Content are handled on the UI
                foreach (var item in GetChildren(complexType))
                {
                    Traverse(item as XmlSchemaChoice);
                    Traverse(item as XmlSchemaSequence);
                    Traverse(item as XmlSchemaElement);
                }

            _xsdObjectVisitor.EndChildren();
        }

        void Traverse(XmlSchemaChoice choice)
        {
            if (choice == null) return;

            if (_xsdObjectVisitor.IsCircular(choice))
                return;

            Traverse(choice as XmlSchemaGroupBase);
        }

        void Traverse(XmlSchemaSequence nestedSequence)
        {
            if (nestedSequence == null) return;

            Traverse(nestedSequence as XmlSchemaGroupBase);
        }

        void Traverse(XmlSchemaGroupBase orderGroup)
        {
            _xsdObjectVisitor.Visit(orderGroup);
            _xsdObjectVisitor.BeginChildren();

            foreach (var element in orderGroup.Items)
            {
                Traverse(element as XmlSchemaChoice);
                Traverse(element as XmlSchemaSequence);
                Traverse(element as XmlSchemaElement);
            }
            _xsdObjectVisitor.EndChildren();
        }

        static IEnumerable<XmlSchemaAttribute> GetAttributes(XmlSchemaComplexType type)
        {
            var result = new List<XmlSchemaAttribute>();

            if (type == null)
                return result;

            result.AddRange(GetAttributes(type.BaseXmlSchemaType as XmlSchemaComplexType));

            result.AddRange(type.Attributes.Cast<XmlSchemaAttribute>());

            if (type.ContentModel != null)
            {
                var simple = type.ContentModel.Content as XmlSchemaSimpleContentExtension;
                var complex = type.ContentModel.Content as XmlSchemaComplexContentExtension;
                if (simple != null)
                    result.AddRange(simple.Attributes.Cast<XmlSchemaAttribute>());
                else if (complex != null)
                    result.AddRange(complex.Attributes.Cast<XmlSchemaAttribute>());
            }

            return result;
        }

        static IEnumerable<XmlSchemaObject> GetChildren(XmlSchemaComplexType type)
        {
            var result = new List<XmlSchemaObject>();

            if (type == null)
                return result;

            var particle = type.ContentTypeParticle;
            var sequence = particle as XmlSchemaSequence;
            var choice = particle as XmlSchemaChoice;
            var all = particle as XmlSchemaAll;

            if (choice != null)
                //result.AddRange(from XmlSchemaObject e in choice.Items where e is XmlSchemaElement || e is XmlSchemaChoice select e);
                result.Add(choice);
            else if (sequence != null)
                result.AddRange(from XmlSchemaObject e in sequence.Items
                                where e is XmlSchemaElement || e is XmlSchemaChoice || e is XmlSchemaSequence
                                select e);
            else if (all != null)
                result.AddRange(from XmlSchemaObject e in all.Items
                                where e is XmlSchemaElement || e is XmlSchemaChoice || e is XmlSchemaSequence
                                select e);

            return result;
        }
    }
}