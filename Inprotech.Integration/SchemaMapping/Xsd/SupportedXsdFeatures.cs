using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml;
using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    internal class SupportedXsdFeatures
    {
        static readonly Type[] SupportedRootItems =
        {
            typeof(XmlSchemaAnnotation),
            typeof(XmlSchemaNotation),
            typeof(XmlSchemaSimpleType),
            typeof(XmlSchemaComplexType),
            typeof(XmlSchemaElement),
            typeof(XmlSchemaAttribute),
            typeof(XmlSchemaAttributeGroup)
        };

        readonly XsdManager _xsdManager;

        readonly Stack<XmlSchemaElement> _visited;

        public SupportedXsdFeatures(XsdManager xsdManager)
        {
            _xsdManager = xsdManager ?? throw new ArgumentNullException(nameof(xsdManager));

            _visited = new Stack<XmlSchemaElement>();
        }

        public void Validate()
        {
            var schema = _xsdManager.Schema;

            if (!schema.IsCompiled)
            {
                throw new Exception("schema not complied");
            }

            var items = schema.Items.Cast<XmlSchemaObject>().ToArray();

            if (items.Any(_ => !SupportedRootItems.Contains(_.GetType())))
            {
                throw new Exception("invalid root element");
            }

            ValidateElement(_xsdManager.RootElement);
        }

        void ValidateElement(XmlSchemaElement element)
        {
            if (!ValidateSubstitutionGroup(element.SubstitutionGroup))
            {
                throw new XsdNotSupportedException(element);
            }

            if (!ValidateBlock(element.Block))
            {
                throw new XsdNotSupportedException(element);
            }

            if (element.ElementSchemaType == null)
            {
                throw new XsdNotSupportedException(element);
            }

            if (_visited.Any(_ => _.QualifiedName == element.QualifiedName && _.ElementSchemaType == element.ElementSchemaType))
            {
                return;
            }

            _visited.Push(element);
            ValidateSchemaType(element.ElementSchemaType);
        }

        void ValidateAttributes(XmlSchemaObjectCollection attributes)
        {
            if (attributes == null || attributes.Count == 0)
            {
                return;
            }

            foreach (var item in attributes)
            {
                var attr = item as XmlSchemaAttribute;
                if (attr != null)
                {
                    ValidateAttribute(attr);
                }
                else if (!(item is XmlSchemaAttributeGroup) && !(item is XmlSchemaAttributeGroupRef))
                {
                    throw new XsdNotSupportedException(item);
                }
            }
        }

        void ValidateAttribute(XmlSchemaAttribute attribute)
        {
            if (attribute.AttributeSchemaType == null)
            {
                throw new XsdNotSupportedException(attribute);
            }

            ValidateSchemaType(attribute.AttributeSchemaType);
        }        

        void ValidateSchemaType(XmlSchemaType type)
        {
            //This is very important to build names for anonymous types
            _xsdManager.EnsureSchemaType(type);

            if (type.IsBuiltIn())
            {
                return;
            }

            //if (type.IsMixed)
            //    throw new XsdNotSupportedException(type);

            var simple = type as XmlSchemaSimpleType;
            var complex = type as XmlSchemaComplexType;

            if (simple != null)
            {
                ValidateSimpleType(simple);
            }
            else if (complex != null)
            {
                ValidateComplexType(complex);
            }
            else
            {
                throw new XsdNotSupportedException(type);
            }

            if (type.BaseXmlSchemaType == null)
            {
                throw new XsdNotSupportedException(type);
            }
        }

        void ValidateSimpleType(XmlSchemaSimpleType type)
        {
            ValidateSimpleTypeContent(type.Content);
        }

        void ValidateSimpleTypeContent(XmlSchemaSimpleTypeContent content)
        {
            if (content == null)
            {
                return;
            }

            var restriction = content as XmlSchemaSimpleTypeRestriction;
            var union = content as XmlSchemaSimpleTypeUnion;

            if (restriction != null)
            {
                ValidateSimpleTypeRestriction(restriction);
            }
            else if (union != null)
            {
                ValidateSimpleTypeUnion(union);
            }
            else
            {
                throw new XsdNotSupportedException(content);
            }
        }

        void ValidateSimpleTypeRestriction(XmlSchemaSimpleTypeRestriction restriction)
        {
            ValidateFacets(restriction.Facets);

            ValidateSchemaType(((XmlSchemaSimpleType)restriction.Parent).BaseXmlSchemaType);
        }

        void ValidateSimpleTypeUnion(XmlSchemaSimpleTypeUnion union)
        {
            foreach (var t in union.BaseMemberTypes)
                ValidateSchemaType(t);
        }

        void ValidateComplexType(XmlSchemaComplexType type)
        {
            if (!ValidateBlock(type.Block))
            {
                throw new XsdNotSupportedException(type);
            }

            if (type.AnyAttribute != null)
            {
                throw new XsdNotSupportedException(type);
            }

            ValidateContentModel(type.ContentModel);

            ValidateAttributes(type.Attributes);

            ValidateParticle(type.ContentTypeParticle);
        }

        void ValidateContentModel(XmlSchemaContentModel contentModel)
        {
            if (contentModel == null)
            {
                return;
            }

            var simple = contentModel as XmlSchemaSimpleContent;
            var complex = contentModel as XmlSchemaComplexContent;

            if (simple != null)
            {
                ValidateSimpleContent(simple.Content);
            }
            else if (complex != null)
            {
                ValidateComplexContent(complex.Content);
            }
            else
            {
                throw new XsdNotSupportedException(contentModel);
            }
        }

        void ValidateSimpleContent(XmlSchemaContent content)
        {
            var extension = content as XmlSchemaSimpleContentExtension;
            var restriction = content as XmlSchemaSimpleContentRestriction;

            if (extension != null)
            {
                if (extension.AnyAttribute != null)
                {
                    throw new XsdNotSupportedException(extension);
                }

                ValidateAttributes(extension.Attributes);
            }
            else if (restriction != null)
            {
                if (restriction.Attributes.Count > 0)
                {
                    throw new XsdNotSupportedException(restriction);
                }

                if (restriction.AnyAttribute != null)
                {
                    throw new XsdNotSupportedException(restriction);
                }

                ValidateFacets(restriction.Facets);
            }
            else
            {
                throw new XsdNotSupportedException(content);
            }

            ValidateSchemaType(((XmlSchemaComplexType)content.Parent.Parent).BaseXmlSchemaType);
        }

        void ValidateComplexContent(XmlSchemaContent content)
        {
            var extension = content as XmlSchemaComplexContentExtension;
            var restriction = content as XmlSchemaComplexContentRestriction;

            if (extension != null)
            {
                if (extension.AnyAttribute != null)
                {
                    throw new XsdNotSupportedException(extension);
                }

                ValidateAttributes(extension.Attributes);
            }
            else if (restriction != null)
            {
                if (restriction.AnyAttribute != null)
                {
                    throw new XsdNotSupportedException(restriction);
                }
            }
            else
            {
                throw new XsdNotSupportedException(content);
            }

            ValidateSchemaType(((XmlSchemaComplexType)content.Parent.Parent).BaseXmlSchemaType);
        }
        void ValidateFacets(XmlSchemaObjectCollection facets)
        {
            if (facets == null || facets.Count == 0)
            {
                return;
            }

            var hasEnum = false;

            foreach (var facet in facets)
            {
                if (facet is XmlSchemaEnumerationFacet)
                {
                    hasEnum = true;
                    continue;
                }

                if (hasEnum)
                {
                    throw new XsdNotSupportedException(facet);
                }

                /*
                 maxInclusive
                 length
                 minLength
                 maxLength
                 pattern
                 maxExclusive
                 minInclusive
                 minExclusive
                 totalDigits
                 fractionDigits
                 whiteSpace
                */
            }
        }

        void ValidateParticle(XmlSchemaParticle particle)
        {
            if (particle == null || particle.GetType().Name == "EmptyParticle")
            {
                return;
            }

            var all = particle as XmlSchemaAll;
            var sequence = particle as XmlSchemaSequence;
            var choice = particle as XmlSchemaChoice;

            if (all != null)
            {
                ValidateAll(all);
            }
            else if (sequence != null)
            {
                ValidateSequence(sequence);
            }
            else if (choice != null)
            {
                ValidateChoice(choice);
            }
            else
            {
                throw new XsdNotSupportedException(particle);
            }
        }

        void ValidateAll(XmlSchemaAll all)
        {
            foreach (var item in all.Items)
            {
                var element = item as XmlSchemaElement;

                if (element != null)
                {
                    ValidateElement(element);
                }
                else
                {
                    throw new XsdNotSupportedException(all);
                }
            }
        }

        void ValidateSequence(XmlSchemaSequence sequence)
        {
            foreach (var item in sequence.Items)
            {
                var element = item as XmlSchemaElement;
                var choice = item as XmlSchemaChoice;
                var nestedSequence = item as XmlSchemaSequence;

                if (element != null)
                {
                    ValidateElement(element);
                }
                else if (choice != null)
                {
                    ValidateChoice(choice);
                }
                else if (nestedSequence != null)
                {
                    ValidateSequence(nestedSequence);
                }
                else
                {
                    throw new XsdNotSupportedException(item);
                }
            }
        }

        void ValidateChoice(XmlSchemaChoice choice)
        {
            foreach (var item in choice.Items)
            {
                var element = item as XmlSchemaElement;
                var sequence = item as XmlSchemaSequence;
                if (element != null)
                {
                    ValidateElement(element);
                }
                else if (sequence != null)
                {
                    ValidateSequence(sequence);
                }
                else if (!(item is XmlSchemaAny))
                {
                    throw new XsdNotSupportedException(item);
                }
            }
        }

        bool ValidateSubstitutionGroup(XmlQualifiedName group)
        {
            if (group != null && !group.IsEmpty)
            {
                return false;
            }

            return true;
        }

        bool ValidateBlock(XmlSchemaDerivationMethod block)
        {
            if (block != XmlSchemaDerivationMethod.None)
            {
                return false;
            }

            return true;
        }
    }
}