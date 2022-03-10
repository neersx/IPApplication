using System;
using System.IO;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Monitoring;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.IntegrationServer
{
    public class IntegrationServerClient : IIntegrationServerClient
    {
        readonly Uri _baseIntegrationServerUrl;
        readonly ICurrentOperationIdProvider _currentOperationIdProvider;
        readonly ISessionAccessTokenGenerator _sessionAccessTokenGenerator;
        readonly ITransientAccessTokenResolver _transientAccessTokenResolver;
        
        public IntegrationServerClient(IAppSettingsProvider appSettingsProvider,
                                       ICurrentOperationIdProvider currentOperationIdProvider,
                                       ISessionAccessTokenGenerator sessionAccessTokenGenerator, 
                                       ITransientAccessTokenResolver transientAccessTokenResolver)
        {
            _currentOperationIdProvider = currentOperationIdProvider;
            _sessionAccessTokenGenerator = sessionAccessTokenGenerator;
            _transientAccessTokenResolver = transientAccessTokenResolver;
            _baseIntegrationServerUrl = new Uri(appSettingsProvider["IntegrationServerBaseUrl"]);
        }

        public async Task<string> DownloadString(string api)
        {
            if (string.IsNullOrWhiteSpace(api)) throw new ArgumentNullException(nameof(api));

            var url = new Uri(_baseIntegrationServerUrl, api);

            using (var handler = new HttpClientHandler { UseCookies = false })
            using (var client = new HttpClient(handler) { BaseAddress = url })
            using (var request = await CreateApiKeyProtectedMessage(HttpMethod.Get, url))
            {
                var response = await client.SendAsync(request);
                response.EnsureSuccessStatusCode();

                return await response.Content.ReadAsStringAsync();
            }
        }

        public async Task<Stream> DownloadContent(string api)
        {
            if (string.IsNullOrWhiteSpace(api)) throw new ArgumentNullException(nameof(api));

            var url = new Uri(_baseIntegrationServerUrl, api);

            using (var handler = new HttpClientHandler { UseCookies = false })
            using (var client = new HttpClient(handler) { BaseAddress = url })
            using (var request = await CreateApiKeyProtectedMessage(HttpMethod.Get, url))
            {
                var response = await client.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    return Stream.Null;
                }

                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStreamAsync();
            }
        }

        public async Task<HttpResponseMessage> GetResponse(string api)
        {
            if (string.IsNullOrWhiteSpace(api)) throw new ArgumentNullException(nameof(api));

            var url = new Uri(_baseIntegrationServerUrl, api);

            using (var handler = new HttpClientHandler { UseCookies = false })
            using (var client = new HttpClient(handler) { BaseAddress = url })
            using (var request = await CreateApiKeyProtectedMessage(HttpMethod.Get, url))
            {
                client.NoTimeout();

                return await client.SendAsync(request);
            }
        }

        public async Task Post(string relativeUrl, object messageContent)
        {
            if (string.IsNullOrWhiteSpace(relativeUrl)) throw new ArgumentNullException(nameof(relativeUrl));
            if (messageContent == null) throw new ArgumentNullException(nameof(messageContent));

            var url = new Uri(_baseIntegrationServerUrl, relativeUrl);

            using (var handler = new HttpClientHandler())
            using (var client = new HttpClient(handler) { BaseAddress = url })
            using (var message = await CreateApiKeyProtectedMessage(HttpMethod.Post, url, messageContent))
            {
                var response = await client.SendAsync(message);
                response.EnsureSuccessStatusCode();
            }
        }

        public async Task<HttpResponseMessage> Put(string relativeUrl, object messageContent)
        {
            if (string.IsNullOrWhiteSpace(relativeUrl)) throw new ArgumentNullException(nameof(relativeUrl));
            if (messageContent == null) throw new ArgumentNullException(nameof(messageContent));

            var url = new Uri(_baseIntegrationServerUrl, relativeUrl);

            using (var handler = new HttpClientHandler())
            using (var client = new HttpClient(handler) { BaseAddress = url })
            using (var message = await CreateApiKeyProtectedMessage(HttpMethod.Put, url, messageContent))
            {
                var response = await client.SendAsync(message);
                response.EnsureSuccessStatusCode();

                return response;
            }
        }

        async Task<HttpRequestMessage> CreateApiKeyProtectedMessage(HttpMethod method, Uri api)
        {
            var message = new HttpRequestMessage(method, api);
            
            if (!_transientAccessTokenResolver.TryResolve(out var token))
            {
                token = await _sessionAccessTokenGenerator.GetOrCreateAccessToken();
            }

            message.Headers.Add("X-ApiKey", token.ToString());
            message.Headers.Add(OperationContexts.RequestIdHeader, _currentOperationIdProvider.OperationId);

            return message;
        }

        async Task<HttpRequestMessage> CreateApiKeyProtectedMessage<T>(HttpMethod method, Uri api, T value = default(T))
        {
            var message = await CreateApiKeyProtectedMessage(method, api);

            if (method == HttpMethod.Put || method == HttpMethod.Post)
            {
                message.Content = new ObjectContent<T>(value, new JsonMediaTypeFormatter());
            }

            return message;
        }
    }
}