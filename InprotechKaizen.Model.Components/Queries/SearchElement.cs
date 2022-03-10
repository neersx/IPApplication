using System.Xml.Serialization;

namespace InprotechKaizen.Model.Components.Queries
{
    public class SearchElement
    {
        [XmlText]
        public string Value { get; set; }

        [XmlAttribute]
        public short Operator { get; set; }
    }
}