using System.Xml.Schema;
using Newtonsoft.Json;

namespace Inprotech.Integration.SchemaMapping.Xsd.Data
{
    public class Attribute : XsdNode
    {
        readonly XmlSchemaAttribute _attribute;

        public Attribute(XmlSchemaAttribute attribute) : base(attribute)
        {
            _attribute = attribute;
        }

        public override string NodeType => "attribute";

        public override string Name => _attribute.RefName.IsEmpty ? _attribute.Name : _attribute.RefName.Name;

        public override string Namespace => _attribute.RefName.IsEmpty ? _attribute.QualifiedName.Namespace : _attribute.RefName.Namespace;

        public string TypeName => _attribute.AttributeSchemaType.Name;

        public string Use => _attribute.Use.ToString();

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string DefaultValue => _attribute.DefaultValue;

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string FixedValue => _attribute.FixedValue;

        [JsonIgnore]
        public XmlSchemaType XmlSchemaType => _attribute.AttributeSchemaType;
    }
}