using System;
using Newtonsoft.Json;

namespace Inprotech.Integration.Serialization
{
    public interface ISerializeJson
    {
        string Serialize(object @object);
        T Deserialize<T>(string json);
        object Deserialize(string json, Type type);
        object Deserialize(string json);
    }

    public class JsonSerializer : ISerializeJson
    {
        public string Serialize(object @object)
        {
            return JsonConvert.SerializeObject(@object);
        }

        public T Deserialize<T>(string json)
        {
            return JsonConvert.DeserializeObject<T>(json);
        }

        public object Deserialize(string json, Type type)
        {
            return JsonConvert.DeserializeObject(json, type);
        }

        public object Deserialize(string json)
        {
            return JsonConvert.DeserializeObject(json);
        }
    }
}