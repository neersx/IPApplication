using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Microsoft.Rest;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Innography
{
    public class InnographyClientSettings
    {
        public InnographyClientSettings(string hmacCryptoAlgorithm = "hmac-sha1")
        {
            AdditionalHeaders = new Dictionary<string, string>();
            HmacCryptoAlgorithm = hmacCryptoAlgorithm;
        }

        public string Version { get; set; }

        public string ClientId { get; set; }

        public string ClientSecret { get; set; }

        public string ServiceType { get; set; }

        public string HmacCryptoAlgorithm { get; set; }

        public Dictionary<string, string> AdditionalHeaders { get; set; }
    }

    public interface IInnographyClient
    {
        Task<T> Post<T>(InnographyClientSettings innographyClientSettings, Uri api, dynamic data = null);

        Task<T> Get<T>(InnographyClientSettings innographyClientSettings, Uri api);

        Task Delete(InnographyClientSettings innographyClientSettings, Uri api);

        Task<byte[]> Download(InnographyClientSettings innographyClientSettings, Uri api);

        Task<T> Patch<T>(InnographyClientSettings innographyClientSettings, Uri api, dynamic data);
    }

    public class InnographyClient : IInnographyClient
    {
        readonly IFileSystem _fileSystem;
        readonly Func<InnographyRequestMessage> _messageCreator;

        public InnographyClient(Func<InnographyRequestMessage> messageCreator, IFileSystem fileSystem)
        {
            _messageCreator = messageCreator;
            _fileSystem = fileSystem;
        }

        public async Task<T> Post<T>(InnographyClientSettings innographyClientSettings, Uri api, dynamic data = null)
        {
            return await PostOrPatch<T>(HttpMethod.Post, innographyClientSettings, api, data);
        }

        public async Task<T> Get<T>(InnographyClientSettings innographyClientSettings, Uri api)
        {
            if (innographyClientSettings == null) throw new ArgumentNullException(nameof(innographyClientSettings));
            if (api == null) throw new ArgumentNullException(nameof(api));

            JObject error = null;

            try
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();

                ServiceClientTracing.Enter(invocationId, this, "Innography:GET", new Dictionary<string, object>());

                var innographyApiRequest = _messageCreator();

                using (var handler = new HttpClientHandler {UseCookies = false})
                using (var client = new HttpClient(handler) {BaseAddress = api})
                using (var request = innographyApiRequest.CreateForNonContentMethod(HttpMethod.Get, api, innographyClientSettings.ClientId, innographyClientSettings.ClientSecret, innographyClientSettings.Version))
                {
                    client.NoTimeout();

                    foreach (var keyValuePair in innographyClientSettings.AdditionalHeaders)
                        request.Headers.Add(keyValuePair.Key, keyValuePair.Value);

                    handler.Credentials = CredentialCache.DefaultNetworkCredentials;

                    ServiceClientTracing.SendRequest(invocationId, request);

                    var response = await client.SendAsync(request);

                    ServiceClientTracing.ReceiveResponse(invocationId, response);

                    dynamic result = await response.Content.ReadAsStringAsync();

                    if (!response.IsSuccessStatusCode)
                    {
                        ServiceClientTracing.Error(invocationId, new HttpOperationException($"Operation returned an invalid status code '{response.StatusCode}'")
                        {
                            Request = new HttpRequestMessageWrapper(request, null),
                            Response = new HttpResponseMessageWrapper(response, result)
                        });

                        error = string.IsNullOrWhiteSpace(result)
                            ? new JObject()
                            : JsonConvert.DeserializeObject<JObject>(result);

                        error.Add("StatusCode", new JValue((int) response.StatusCode));
                        error.Add("ReasonPhrase", response.ReasonPhrase);
                        error.Add("RequestUrl", api);

                        response.EnsureSuccessStatusCode();
                    }

                    ServiceClientTracing.Exit(invocationId, result);

                    return typeof(T) == typeof(string)
                        ? (T) result
                        : (T) JsonConvert.DeserializeObject<T>(result);
                }
            }
            catch (HttpRequestException ex)
            {
                if (error == null)
                {
                    throw;
                }

                throw new InnographyIntegrationException(error, ex);
            }
        }

        public async Task<T> Patch<T>(InnographyClientSettings innographyClientSettings, Uri api, dynamic data)
        {
            return await PostOrPatch<T>(new HttpMethod("Patch"), innographyClientSettings, api, data);
        }

        public async Task Delete(InnographyClientSettings innographyClientSettings, Uri api)
        {
            if (innographyClientSettings == null) throw new ArgumentNullException(nameof(innographyClientSettings));
            if (api == null) throw new ArgumentNullException(nameof(api));

            JObject error = null;

            try
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();

                ServiceClientTracing.Enter(invocationId, this, "Innography:DELETE", new Dictionary<string, object>());

                var innographyApiRequest = _messageCreator();

                using (var handler = new HttpClientHandler {UseCookies = false})
                using (var client = new HttpClient(handler) {BaseAddress = api})
                using (var request = innographyApiRequest.CreateForNonContentMethod(HttpMethod.Delete, api, innographyClientSettings.ClientId, innographyClientSettings.ClientSecret, innographyClientSettings.Version))
                {
                    client.NoTimeout();

                    handler.Credentials = CredentialCache.DefaultNetworkCredentials;

                    ServiceClientTracing.SendRequest(invocationId, request);

                    var response = await client.SendAsync(request);

                    ServiceClientTracing.ReceiveResponse(invocationId, response);

                    var result = await response.Content.ReadAsStringAsync();

                    if (!response.IsSuccessStatusCode)
                    {
                        ServiceClientTracing.Error(invocationId, new HttpOperationException($"Operation returned an invalid status code '{response.StatusCode}'")
                        {
                            Request = new HttpRequestMessageWrapper(request, null),
                            Response = new HttpResponseMessageWrapper(response, result)
                        });

                        error = string.IsNullOrWhiteSpace(result)
                            ? new JObject()
                            : JsonConvert.DeserializeObject<JObject>(result);

                        error.Add("StatusCode", new JValue((int) response.StatusCode));
                        error.Add("ReasonPhrase", response.ReasonPhrase);
                        error.Add("RequestUrl", api);

                        response.EnsureSuccessStatusCode();
                    }
                    
                    ServiceClientTracing.Exit(invocationId, result);
                }
            }
            catch (HttpRequestException ex)
            {
                if (error == null)
                {
                    throw;
                }

                throw new InnographyIntegrationException(error, ex);
            }
        }

        public async Task<byte[]> Download(InnographyClientSettings innographyClientSettings, Uri api)
        {
            if (innographyClientSettings == null) throw new ArgumentNullException(nameof(innographyClientSettings));
            if (api == null) throw new ArgumentNullException(nameof(api));

            JObject error = null;

            try
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();

                ServiceClientTracing.Enter(invocationId, this, "Innography:DOWNLOAD", new Dictionary<string, object>());

                var innographyApiRequest = _messageCreator();

                using (var handler = new HttpClientHandler {UseCookies = false})
                using (var client = new HttpClient(handler) {BaseAddress = api})
                using (var request = innographyApiRequest.CreateForNonContentMethod(HttpMethod.Get, api, innographyClientSettings.ClientId, innographyClientSettings.ClientSecret, innographyClientSettings.Version))
                {
                    client.NoTimeout();

                    foreach (var keyValuePair in innographyClientSettings.AdditionalHeaders)
                        request.Headers.Add(keyValuePair.Key, keyValuePair.Value);

                    handler.Credentials = CredentialCache.DefaultNetworkCredentials;

                    ServiceClientTracing.SendRequest(invocationId, request);

                    var response = await client.SendAsync(request);

                    ServiceClientTracing.ReceiveResponse(invocationId, null);

                    if (!response.IsSuccessStatusCode)
                    {
                        var result = await response.Content.ReadAsStringAsync();

                        ServiceClientTracing.Error(invocationId, new HttpOperationException($"Operation returned an invalid status code '{response.StatusCode}'")
                        {
                            Request = new HttpRequestMessageWrapper(request, null),
                            Response = new HttpResponseMessageWrapper(response, result)
                        });

                        error = string.IsNullOrWhiteSpace(result)
                            ? new JObject()
                            : JsonConvert.DeserializeObject<JObject>(result);

                        error.Add("StatusCode", new JValue((int) response.StatusCode));
                        error.Add("ReasonPhrase", response.ReasonPhrase);
                        error.Add("RequestUrl", api);

                        response.EnsureSuccessStatusCode();
                    }

                    var returnValue = await response.Content.ReadAsByteArrayAsync();

                    ServiceClientTracing.Exit(invocationId, $"Document downloaded ({returnValue.Length} bytes)");

                    return returnValue;
                }
            }
            catch (HttpRequestException ex)
            {
                if (error == null)
                {
                    throw;
                }

                throw new InnographyIntegrationException(error, ex);
            }
        }

        async Task<T> PostOrPatch<T>(HttpMethod method, InnographyClientSettings innographyClientSettings, Uri api, dynamic data = null)
        {
            if (innographyClientSettings == null) throw new ArgumentNullException(nameof(innographyClientSettings));
            if (api == null) throw new ArgumentNullException(nameof(api));

            JObject error = null;

            try
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();

                ServiceClientTracing.Enter(invocationId, this, $"Innography:{method.ToString().ToUpper()}", new Dictionary<string, object>());

                var innographyApiRequest = _messageCreator();

                using (var handler = new HttpClientHandler {UseCookies = false})
                using (var client = new HttpClient(handler) {BaseAddress = api})
                using (var request = await innographyApiRequest.Create(method, api, innographyClientSettings.ClientId, innographyClientSettings.ClientSecret, innographyClientSettings.Version, innographyClientSettings.HmacCryptoAlgorithm, data))
                {
                    client.NoTimeout();

                    foreach (var keyValuePair in innographyClientSettings.AdditionalHeaders)
                        request.Headers.Add(keyValuePair.Key, keyValuePair.Value);

                    handler.Credentials = CredentialCache.DefaultNetworkCredentials;
                    
                    ServiceClientTracing.SendRequest(invocationId, request);

                    var response = await client.SendAsync(request);
                    
                    ServiceClientTracing.ReceiveResponse(invocationId, response);

                    var result = await response.Content.ReadAsStringAsync();
                    
                    if (!response.IsSuccessStatusCode)
                    {
                        ServiceClientTracing.Error(invocationId, new HttpOperationException($"Operation returned an invalid status code '{response.StatusCode}'")
                        {
                            Request = new HttpRequestMessageWrapper(request, data == null ? null : JsonConvert.SerializeObject(data)),
                            Response = new HttpResponseMessageWrapper(response, result)
                        });

                        error = string.IsNullOrWhiteSpace(result)
                            ? new JObject()
                            : JsonConvert.DeserializeObject<JObject>(result);

                        error.Add("StatusCode", new JValue((int) response.StatusCode));
                        error.Add("ReasonPhrase", response.ReasonPhrase);
                        error.Add("RequestUrl", api);

                        if (response.StatusCode == HttpStatusCode.InternalServerError && data != null)
                        {
                            var payloadId = Guid.NewGuid();
                            _fileSystem.WriteAllText($"Innography\\Troubleshooting\\{payloadId}.json", JsonConvert.SerializeObject(data, Formatting.Indented));
                            error.Add("RequestPayloadId", payloadId);
                        }

                        response.EnsureSuccessStatusCode();
                    }
                    
                    ServiceClientTracing.Exit(invocationId, result);
                    
                    return typeof(T) == typeof(string)
                        ? result
                        : JsonConvert.DeserializeObject<T>(result);
                }
            }
            catch (HttpRequestException ex)
            {
                if (error == null)
                {
                    throw;
                }

                throw new InnographyIntegrationException(error, ex);
            }
        }
    }

    [SuppressMessage("Microsoft.Usage", "CA2240:ImplementISerializableCorrectly")]
    [Serializable]
    public class InnographyIntegrationException : Exception
    {
        public InnographyIntegrationException(JObject integrationError, Exception innerException)
            : base("Innography integration error. " + Environment.NewLine + integrationError.ToString(Formatting.Indented), innerException)
        {
            StatusCode = (HttpStatusCode) (int) integrationError["StatusCode"];
        }

        public InnographyIntegrationException(JObject integrationError)
            : this(integrationError, null)
        {
            StatusCode = (HttpStatusCode) (int) integrationError["StatusCode"];
        }

        public HttpStatusCode StatusCode { get; }
    }
}