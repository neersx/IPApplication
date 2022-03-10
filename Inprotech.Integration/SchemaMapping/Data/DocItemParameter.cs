using System;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.SchemaMapping.Data
{
    abstract class DocItemParameter
    {
        public string Id;

        public string Type;
    }

    class FixedParameter : DocItemParameter
    {
        public object Value;
    }

    class GlobalParameter : DocItemParameter
    {        
    }

    class BoundColumnParameter : DocItemParameter
    {
        public string NodeId;

        public int ColumnId;

        public int DocItemId;
    }

    class DocItemParameterConverter : JsonConverter
    {
        public override bool CanConvert(Type objectType)
        {
            return typeof(DocItemParameter).IsAssignableFrom(objectType);
        }

        public override object ReadJson(JsonReader reader,
            Type objectType, object existingValue, JsonSerializer serializer)
        {
            JObject item = JObject.Load(reader);
            var type = item["type"].Value<string>();
            switch (type)
            {
                case "fixed": return item.ToObject<FixedParameter>();
                case "global": return item.ToObject<GlobalParameter>();               
                case "bind": return item.ToObject<BoundColumnParameter>();               
            }

            throw new Exception("type not supported: " + type);
        }

        public override void WriteJson(JsonWriter writer,
            object value, JsonSerializer serializer)
        {
            throw new NotImplementedException();
        }
    }
}