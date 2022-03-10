using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.IPPlatform.Sso;
using Microsoft.Rest;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public interface IFileApiClient
    {
        Task<T> Get<T>(Uri uri, NotFoundHandling? notFoundHandling = NotFoundHandling.ReturnDefault);
        Task<T> Put<T>(Uri uri, dynamic data = null, NotFoundHandling? notFoundHandling = NotFoundHandling.ReturnDefault);
        Task<T> Post<T>(Uri uri, dynamic data, NotFoundHandling? notFoundHandling = NotFoundHandling.ReturnDefault);
    }

    public enum NotFoundHandling
    {
        ReturnDefault,
        Throw404
    }

    public class FileApiClient : IFileApiClient
    {
        readonly IAccessTokenProvider _accessTokenProvider;

        public FileApiClient(IAccessTokenProvider accessTokenProvider)
        {
            _accessTokenProvider = accessTokenProvider;
        }
        
        public Task<T> Get<T>(Uri uri, NotFoundHandling? notFoundHandling = NotFoundHandling.ReturnDefault)
        {
            return Send<T>(HttpMethod.Get, uri, notFoundHandling: notFoundHandling);
        }

        public Task<T> Put<T>(Uri uri, dynamic data = null, NotFoundHandling? notFoundHandling = NotFoundHandling.ReturnDefault)
        {
            return Send<T>(HttpMethod.Put, uri, data, notFoundHandling);
        }

        public Task<T> Post<T>(Uri uri, dynamic data, NotFoundHandling? notFoundHandling = NotFoundHandling.ReturnDefault)
        {
            return Send<T>(HttpMethod.Post, uri, data, notFoundHandling);
        }

        async Task<T> Send<T>(HttpMethod method, Uri api, dynamic data = null, NotFoundHandling? notFoundHandling = NotFoundHandling.ReturnDefault)
        {
            JObject error = null;

            try
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();

                ServiceClientTracing.Enter(invocationId, this, $"FILE:{method.ToString().ToUpper()}", new Dictionary<string, object>());

                using (var handler = new HttpClientHandler {UseCookies = false})
                using (var client = new HttpClient(handler) {BaseAddress = api})
                using (var request = new HttpRequestMessage(method, api))
                {
                    client.NoTimeout();

                    if (data != null)
                    {
                        var serialised = JsonConvert.SerializeObject(data, new JsonSerializerSettings
                        {
                            NullValueHandling = NullValueHandling.Ignore,
                            ContractResolver = new CamelCasePropertyNamesContractResolver()
                        });

                        request.Content = new StringContent(serialised, Encoding.UTF8, "application/json");
                    }

                    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _accessTokenProvider.GetAccessToken());

                    handler.Credentials = CredentialCache.DefaultNetworkCredentials;

                    ServiceClientTracing.SendRequest(invocationId, request);

                    var response = await client.SendAsync(request);
                    
                    ServiceClientTracing.ReceiveResponse(invocationId, response);

                    var result = await response.Content.ReadAsStringAsync();

                    if (!response.IsSuccessStatusCode)
                    {
                        if (response.StatusCode == HttpStatusCode.NotFound && notFoundHandling == NotFoundHandling.ReturnDefault)
                        {
                            return default(T);
                        }

                        ServiceClientTracing.Error(invocationId, new HttpOperationException($"Operation returned an invalid status code '{response.StatusCode}'")
                        {
                            Request = new HttpRequestMessageWrapper(request, null),
                            Response = new HttpResponseMessageWrapper(response, result)
                        });

                        error = string.IsNullOrWhiteSpace(result) 
                            ? new JObject() 
                            : JsonConvert.DeserializeObject<JObject>(result);

                        error.Add("StatusCode", new JValue((int)response.StatusCode));
                        error.Add("ReasonPhrase", response.ReasonPhrase);
                        error.Add("RequestUrl", api);

                        response.EnsureSuccessStatusCode();
                    }
                    
                    ServiceClientTracing.Exit(invocationId, result);

                    return JsonConvert.DeserializeObject<T>(result);
                }
            }
            catch (HttpRequestException ex)
            {
                if (error == null)
                {
                    throw;
                }

                throw new FileIntegrationException(error, ex);
            }
        }
    }
}