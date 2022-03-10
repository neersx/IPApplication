using System.Net.Http;
using Newtonsoft.Json.Linq;

namespace Inprotech.Tests.Extensions
{
    public static class HttpResponseMessageExtensions
    {
        public static dynamic GetObject(this HttpResponseMessage message)
        {
            var content = message.Content.ReadAsStringAsync().Result;
            dynamic r = JObject.Parse(content);

            return r;
        }
    }
}