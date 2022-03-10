using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.Xsd.Data
{
    internal class Choice : XsdNode
    {
        readonly XmlSchemaChoice _choice;

        public Choice(XmlSchemaChoice choice) : base(choice)
        {
            _choice = choice;
        }

        public override string NodeType => "Choice";

        public override string Name => "Choice";

        public override string Namespace => string.Empty;

        public string MinOccurs => _choice.MinOccursString ?? _choice.MinOccurs.ToString();

        public string MaxOccurs => _choice.MaxOccursString ?? _choice.MaxOccurs.ToString();
    }
}