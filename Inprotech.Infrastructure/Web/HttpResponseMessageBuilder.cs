using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Infrastructure.Web
{
    public static class HttpResponseMessageBuilder
    {
        public static HttpResponseMessage Json(HttpStatusCode statusCode, object obj)
        {
            return new HttpResponseMessage
            {
                StatusCode = statusCode,
                Content =
                    new StringContent(
                                      JsonConvert.SerializeObject(obj,
                                                                  new JsonSerializerSettings {ContractResolver = new CamelCasePropertyNamesContractResolver()}),
                                      Encoding.UTF8, "application/json")
            };
        }

        public static HttpResponseMessage Html(HttpStatusCode statusCode, string message)
        {
            return new HttpResponseMessage
            {
                StatusCode = statusCode,
                Content =
                    new StringContent(message, Encoding.UTF8, "text/html")
            };
        }

        public static HttpResponseMessage Xml(HttpStatusCode statusCode, string xml)
        {
            return new HttpResponseMessage
            {
                Content = new StringContent(xml, Encoding.UTF8, "application/xml")
            };
        }

        public static HttpResponseMessage File(string filename, Stream stream)
        {
            var response = new HttpResponseMessage
            {
                Content = new StreamContent(stream)
            };

            response.Content.Headers.ContentType = new MediaTypeHeaderValue(MimeMapping.GetMimeMapping(filename));
            response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
            {
                FileName = filename
            };

            return response;
        }

        public static HttpResponseMessage File(string filename, string content)
        {
            var response = new HttpResponseMessage
            {
                Content = new StringContent(content)
            };

            response.Content.Headers.ContentType = new MediaTypeHeaderValue(MimeMapping.GetMimeMapping(filename));
            response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
            {
                FileName = filename
            };

            return response;
        }
    }
}