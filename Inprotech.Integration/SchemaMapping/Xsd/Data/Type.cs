using System.Xml.Schema;
using Newtonsoft.Json;

namespace Inprotech.Integration.SchemaMapping.Xsd.Data
{
    public class Type
    {
        public Type(XmlSchemaType type)
        {
            Name = type.Name;

            if (type.Datatype != null)
                DataType = type.Datatype.TypeCode.ToString();

            if (type.Datatype == null && type.IsMixed)
                DataType = XmlTypeCode.String.ToString();

            if (DataType == null && (type as XmlSchemaComplexType)?.ContentType == XmlSchemaContentType.Empty)
                DataType = XmlTypeCode.None.ToString();

            if (!type.IsBuiltIn())
            {
                Line = type.LineNumber;
                Column = type.LinePosition;
            }
        }

        public string Name { get; internal set; }

        public string DataType { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public int? Line { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public int? Column { get; internal set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public Restriction Restrictions { get; internal set; }
    }
}