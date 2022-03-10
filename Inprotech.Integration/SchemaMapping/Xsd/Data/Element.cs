using System.Xml.Schema;
using Newtonsoft.Json;

namespace Inprotech.Integration.SchemaMapping.Xsd.Data
{
    internal class Element : XsdNode
    {
        readonly XmlSchemaElement _element;

        public Element(XmlSchemaElement element) : base(element)
        {
            _element = element;
        }

        public override string NodeType => "element";

        public override string Name => _element.RefName.IsEmpty ? _element.Name : _element.RefName.Name;

        public override string Namespace => _element.RefName.IsEmpty ? _element.QualifiedName.Namespace : _element.RefName.Namespace;

        public string TypeName => _element.ElementSchemaType.Name;

        public string MinOccurs => _element.MinOccursString ?? _element.MinOccurs.ToString();

        public string MaxOccurs => _element.MaxOccursString ?? _element.MaxOccurs.ToString();

        public bool IsEmpty => (XmlSchemaType as XmlSchemaComplexType)?.ContentType == XmlSchemaContentType.Empty;

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string DefaultValue => _element.DefaultValue;

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string FixedValue => _element.FixedValue;

        [JsonIgnore]
        public XmlSchemaType XmlSchemaType => _element.ElementSchemaType;
    }
}