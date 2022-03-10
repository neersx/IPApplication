using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;

namespace Inprotech.Tests.E2e.Integration.Fake
{
    public static class ResponseHelper
    {
        static readonly IDictionary<string, string> MediaTypes = new Dictionary<string, string>
                                                                 {
                                                                     {"html", "text/html"},
                                                                     {"json", "text/json"},
                                                                     {"xml", "text/xml"},
                                                                     {"pdf", "application/pdf"},
                                                                     {"zip", "application/zip"},
                                                                 };

        public static HttpResponseMessage ResponseAsStream(string filePath)
        {
            var response = new HttpResponseMessage(HttpStatusCode.OK);
            response.Content = new StreamContent(new FileStream(GetAbsolutePath(filePath), FileMode.Open));
            response.Content.Headers.ContentType = new MediaTypeHeaderValue(GetMediaType(filePath));

            var contentDisposition = new ContentDispositionHeaderValue("FileName");
            contentDisposition.FileName = Path.GetFileName(filePath);
            response.Content.Headers.ContentDisposition = contentDisposition;

            return response;
        }

        public static HttpResponseMessage RespondWithStream(MemoryStream stream, string fileName, string fileExtension)
        {
            stream.Seek(0, SeekOrigin.Begin);
            var streamContent = new StreamContent(stream);
            var response = new HttpResponseMessage(HttpStatusCode.OK);
            response.Content = streamContent;
            response.Content.Headers.ContentType = new MediaTypeHeaderValue(GetMediaType(fileExtension));

            var contentDisposition = new ContentDispositionHeaderValue("FileName");
            contentDisposition.FileName = fileName;
            response.Content.Headers.ContentDisposition = contentDisposition;

            return response;
        }

        public static HttpResponseMessage ResponseAsString(
            string filePath,
            Func<string, string> alterContent = null)
        {
            var response = new HttpResponseMessage(HttpStatusCode.OK);
            var content = File.ReadAllText(GetAbsolutePath(filePath));

            if (alterContent != null)
                content = alterContent(content);

            response.Content = new StringContent(content);
            response.Content.Headers.ContentType = new MediaTypeHeaderValue(GetMediaType(filePath));

            return response;
        }

        public static string GetAbsolutePath(string filePath)
        {
            return Path.Combine("Contents", filePath);
        }

        public static bool FileExists(string filePath) => File.Exists(GetAbsolutePath(filePath));

        static string GetMediaType(string filePath)
        {
            var ext = Path.GetExtension(filePath);
            return MediaTypes[ext.Substring(1).ToLower()];
        }
    }
}
