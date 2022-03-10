using System;
using System.IO;
using System.Net;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace Inprotech.Infrastructure.Web
{
    public interface IApiClient
    {
        T Get<T>(string url);
        Task<HttpWebResponse> GetAsync(string url);
        T Post<T>(string url, string body);
        Task<T> PostAsync<T>(string url, string body);
        T Put<T>(string url, string body);
        void Put(string url, string body);
        HttpStatusCode Delete(string url);

        ApiClientOptions Options { get; }
    }

    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    public class ApiClientException : Exception
    {
        public ApiClientException(WebException ex)
        {
            var response = ex.Response;
            using var stream = response.GetResponseStream();
            if (stream != null)
            {
                var reader = new StreamReader(stream);
                Message = reader.ReadToEnd();
            }
        }

        public override string Message { get; }
    }

    public class ApiClientOptions
    {
        public ApiClientOptions(ContentTypes contentType)
        {
            ContentType = contentType;
        }

        public enum ContentTypes
        {
            Json,
            Form
        }

        public ContentTypes ContentType { get; set; }
        public bool IgnoreServerCertificateValidation { get; set; }

        internal string ContentTypeString
        {
            get
            {
                switch (ContentType)
                {
                    case ContentTypes.Json:
                        return "application/json";
                    case ContentTypes.Form:
                        return "application/x-www-form-urlencoded";
                }
                throw new Exception("ContentType not defined");
            }
        }
    }

    class ApiClient : IApiClient
    {
        public ApiClientOptions Options { get; }

        public ApiClient()
        {
            Options = new ApiClientOptions(ApiClientOptions.ContentTypes.Json);
        }
        public T Get<T>(string url)
        {
            var request = BuildApiRequest(url);

            request.Method = "GET";
            var response = GetResponse(request);

            return DeserializeResponse<T>(response);
        }

        public async Task<HttpWebResponse> GetAsync(string url)
        {
            var request = BuildApiRequest(url);
            request.Method = "GET";
            return await GetResponseAsync(request);
        }

        public HttpStatusCode Delete(string url)
        {
            var request = BuildApiRequest(url);

            request.Method = "DELETE";
            var response = GetResponse(request);

            return response.StatusCode;
        }

        public void Put(string url, string body)
        {
            CallPut(url, body);
        }

        public T Post<T>(string url, string body)
        {
            var response = CallPost(url, body);
            return DeserializeResponse<T>(response);
        }

        public async Task<T> PostAsync<T>(string url, string body)
        {
            var response = await CallPostAsync(url, body);
            return DeserializeResponse<T>(response);
        }

        public T Put<T>(string url, string body)
        {
            var response = CallPut(url, body);

            return DeserializeResponse<T>(response);
        }

        HttpWebResponse CallPut(string url, string body)
        {
            var request = BuildApiRequest(url);

            request.Method = "PUT";

            using (var writer = new StreamWriter(request.GetRequestStream()))
            {
                writer.Write(body);
            }

            try
            {
                var response = GetResponse(request);
                return response;
            }
            catch (WebException ex)
            {
                throw new ApiClientException(ex);
            }
        }

        HttpWebResponse CallPost(string url, string body)
        {
            var request = BuildApiRequest(url);
            request.Method = "POST";

            using (var writer = new StreamWriter(request.GetRequestStream()))
            {
                writer.Write(body);
            }

            var response = GetResponse(request);
            return response;
        }

        async Task<HttpWebResponse> CallPostAsync(string url, string body)
        {
            var request = BuildApiRequest(url);
            request.Method = "POST";

            using (var writer = new StreamWriter(request.GetRequestStream()))
            {
                writer.Write(body);
            }

            var response = await GetResponseAsync(request);
            return response;
        }

        HttpWebRequest BuildApiRequest(string url)
        {
            var apiUrl = new Uri(url);
            var request = (HttpWebRequest)WebRequest.Create(apiUrl);
            SetRequestOptions(request);
            return request;
        }

        static T DeserializeResponse<T>(HttpWebResponse response)
        {
            using var reader = new StreamReader(response.GetResponseStream());
            
            var str = reader.ReadToEnd();

            if (typeof(T) == typeof(string))
                return (T)(object)str;

            return JsonConvert.DeserializeObject<T>(str);
        }

        HttpWebResponse GetResponse(HttpWebRequest request)
        {
            try
            {
                return (HttpWebResponse)request.GetResponse();
            }
            catch (WebException ex)
            {
                throw new ApiClientException(ex);
            }
        }

        async Task<HttpWebResponse> GetResponseAsync(HttpWebRequest request)
        {
            try
            {
                return (HttpWebResponse)await request.GetResponseAsync();
            }
            catch (WebException ex)
            {
                throw new ApiClientException(ex);
            }
        }

        void SetRequestOptions(HttpWebRequest request)
        {
            request.ContentType = Options.ContentTypeString;

            if (Options.IgnoreServerCertificateValidation)
                request.ServerCertificateValidationCallback += (sender, certificate, chain, sslPolicyErrors) => true;
        }
    }
}