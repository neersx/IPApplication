using System.Collections.Generic;
using System.Linq;
using System.Xml.Schema;
using Inprotech.Integration.SchemaMapping.Xsd.Data;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    class XsdTypeBuilder
    {
        Dictionary<string, Type> _results;

        public IEnumerable<Type> Build(IEnumerable<XmlSchemaType> types)
        {
            _results = new Dictionary<string, Type>();

            foreach (var type in types)
            {
                Build(type);
            }

            return _results.Values;
        }

        Type Build(XmlSchemaType type)
        {
            if (type == null)
                return null;

            Type built;
            _results.TryGetValue(type.Name ?? type.TypeCode.ToString(), out built);

            return built ?? Build(type as XmlSchemaSimpleType) ?? Build(type as XmlSchemaComplexType);
        }

        Type Build(XmlSchemaSimpleType type)
        {
            if (type == null)
                return null;

            if (type.IsBuiltIn())
            {
                var name = type.Name ?? type.TypeCode.ToString();

                return _results[name] = new Type(type);
            }

            var restriction = type.Content as XmlSchemaSimpleTypeRestriction;
            var union = type.Content as XmlSchemaSimpleTypeUnion;

            if (restriction != null)
            {
                var parent = Build(type.BaseXmlSchemaType);

                return _results[type.Name] = new Type(type)
                {
                    Restrictions = Build(restriction.Facets.Cast<XmlSchemaFacet>())
                }.Inherit(parent);
            }

            if (union != null)
            {
                var parentTypes = union.BaseMemberTypes.Select(Build).Select(_ => _.Name).ToArray();

                return _results[type.Name] = new Union(type) { UnionTypes = parentTypes };
            }

            return null;
        }

        Type Build(XmlSchemaComplexType type)
        {
            if (type == null)
                return null;

            if (type.ContentModel == null)
            {
                return _results[type.Name] = new Type(type);
            }

            var restriction = type.ContentModel.Content as XmlSchemaSimpleContentRestriction;
            var extension = type.ContentModel.Content as XmlSchemaSimpleContentExtension;

            if (restriction != null)
            {
                var parent = Build(type.BaseXmlSchemaType);

                return _results[type.Name] = new Type(type)
                {
                    Restrictions = Build(restriction.Facets.Cast<XmlSchemaFacet>())
                }.Inherit(parent);
            }

            if (extension != null)
            {
                var parent = Build(type.BaseXmlSchemaType);

                return _results[type.Name] = new Type(type).Inherit(parent);
            }

            return null;
        }

        Restriction Build(IEnumerable<XmlSchemaFacet> facets)
        {
            var r = new Restriction();
            var options = new List<string>();

            foreach (var facet in facets)
            {
                var enumeration = facet as XmlSchemaEnumerationFacet;
                var length = facet as XmlSchemaLengthFacet;
                var minInclusive = facet as XmlSchemaMinInclusiveFacet;
                var minLength = facet as XmlSchemaMinLengthFacet;
                var maxLength = facet as XmlSchemaMaxLengthFacet;
                var pattern = facet as XmlSchemaPatternFacet;
                var maxInclusive = facet as XmlSchemaMaxInclusiveFacet;
                var maxExclusive = facet as XmlSchemaMaxExclusiveFacet;
                var minExclusive = facet as XmlSchemaMinExclusiveFacet;
                var totalDigits = facet as XmlSchemaTotalDigitsFacet;

                if (enumeration != null)
                    options.Add(enumeration.Value);
                else if (length != null)
                    r.Length = length.Value;
                else if (minInclusive != null)
                    r.MinInclusive = minInclusive.Value;
                else if (minLength != null)
                    r.MinLength = minLength.Value;
                else if (maxLength != null)
                    r.MaxLength = maxLength.Value;
                else if (pattern != null)
                    r.Pattern = pattern.Value;
                else if (maxInclusive != null)
                    r.MaxInclusive = maxInclusive.Value;
                else if (maxExclusive != null)
                    r.MaxExclusive = maxExclusive.Value;
                else if (minExclusive != null)
                    r.MinExclusive = minExclusive.Value;
                else if (totalDigits != null)
                    r.TotalDigits = totalDigits.Value;
            }

            if (options.Any())
                r.Enumerations = options;

            return r;
        }
    }
}