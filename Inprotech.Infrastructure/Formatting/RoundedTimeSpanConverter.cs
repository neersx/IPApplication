using System;
using System.Linq;
using Newtonsoft.Json;

namespace Inprotech.Infrastructure.Formatting
{
    public class RoundedTimeSpanConverter : JsonConverter
    {
        static readonly Type[] SupportedTypes =
        {
                                     typeof (TimeSpan),
                                     typeof (TimeSpan?)
        };

        public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
        {
            if (value == null)
            {
                writer.WriteValue((TimeSpan?)value);
                return;
            }

            var valueToWrite = ((TimeSpan)value).Subtract(TimeSpan.FromMilliseconds(((TimeSpan)value).Milliseconds));
            writer.WriteValue(valueToWrite);
        }

        public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
        {
            throw new NotImplementedException();
        }

        public override bool CanConvert(Type objectType)
        {
            return SupportedTypes.Contains(objectType);
        }
    }
}