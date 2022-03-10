using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.Xsd.Data
{
    internal class Sequence : XsdNode
    {
        readonly XmlSchemaSequence _sequence;

        public Sequence(XmlSchemaSequence sequence) : base(sequence)
        {
            _sequence = sequence;
        }

        public override string NodeType => "Sequence";

        public override string Name => "Sequence";

        public override string Namespace => string.Empty;

        public string MinOccurs => _sequence.MinOccursString ?? _sequence.MinOccurs.ToString();

        public string MaxOccurs => _sequence.MaxOccursString ?? _sequence.MaxOccurs.ToString();
    }
}