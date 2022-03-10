using System.IO;
using System.Xml.Serialization;

namespace Inprotech.Integration.Serialization
{
    public interface ISerializeXml
    {
        string Serialize(object @object);
        T Deserialize<T>(string xml);
    }

    public class XmlSerialization : ISerializeXml
    {
        public string Serialize(object @object)
        {
            if (@object == null) return null;

            using (var stringWriter = new StringWriter())
            {
                var xmlNamespaces = new XmlSerializerNamespaces();
                xmlNamespaces.Add(string.Empty, string.Empty);

                var serializer = new XmlSerializer(@object.GetType());
                serializer.Serialize(stringWriter, @object, xmlNamespaces);
                return stringWriter.ToString();
            }
        }

        public T Deserialize<T>(string xml)
        {
            using TextReader reader = new StringReader(xml);
            return (T)new XmlSerializer(typeof(T)).Deserialize(reader);
        }
    }
}
