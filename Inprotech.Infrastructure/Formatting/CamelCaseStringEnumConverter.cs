using Newtonsoft.Json.Converters;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Infrastructure.Formatting
{
    public class CamelCaseStringEnumConverter : StringEnumConverter
    {
        public CamelCaseStringEnumConverter() : base(new CamelCaseNamingStrategy())
        {
        }
    }
}