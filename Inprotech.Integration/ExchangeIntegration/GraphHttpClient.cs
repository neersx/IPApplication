using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace Inprotech.Integration.ExchangeIntegration
{
    public interface IGraphHttpClient 
    {
        Task<HttpClient> GetClient(int userId);

        Task<HttpResponseMessage> Post<T>(int userId, string url, T payload);

        Task Patch<T>(int userId, string url, T payloads);

        Task Delete(int userId, string url);

        Task<HttpResponseMessage> Get(int userId, string url);
    }

    public class GraphHttpClient : IGraphHttpClient
    {
        readonly IAppSettings _appSettings;
        readonly IGraphAccessTokenManager _graphAccessTokenManager;

        public GraphHttpClient(IAppSettings appSettings,
                                       IGraphAccessTokenManager graphAccessTokenManager
            )
        {
            
            _appSettings = appSettings;
            _graphAccessTokenManager = graphAccessTokenManager;
        }

        public async Task<HttpClient> GetClient(int userId)
        {
            var httpClient = new HttpClient { BaseAddress = new Uri(_appSettings.GraphApiUrl) };
            httpClient.DefaultRequestHeaders.Accept.Clear();
            httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            var token = await _graphAccessTokenManager.GetStoredTokenAsync(userId);
            if (token == null)
                throw new GraphAccessTokenNotAvailableException("This staff has not been configured for Exchange Integration.");

            httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token.AccessToken);
            return httpClient;
        }

        public async Task<HttpResponseMessage> Post<T>(int userId, string url, T payload)
        {
            var httpClient = await GetClient(userId);
            var stringContent = JsonConvert.SerializeObject(payload);
            var content = new StringContent(stringContent, Encoding.UTF8, "application/json");
            var rm = await httpClient.PostAsync(url, content);
            RaiseGraphAccessTokenExpiredException(rm);

            return rm.EnsureSuccessStatusCode();
        }

        public async Task Patch<T>(int userId, string url, T payloads)
        {
            var httpClient = await GetClient(userId);
            var content = new StringContent(JsonConvert.SerializeObject(payloads), Encoding.UTF8, "application/json");
            var httpRequest = new HttpRequestMessage(new HttpMethod("PATCH"), url) { Content = content };
            var rm = await httpClient.SendAsync(httpRequest);
            RaiseGraphAccessTokenExpiredException(rm);

            rm.EnsureSuccessStatusCode();
        }

        public async Task Delete(int userId, string url)
        {
            var httpClient = await GetClient(userId);
            var rm = await httpClient.DeleteAsync(url);
            RaiseGraphAccessTokenExpiredException(rm);

            rm.EnsureSuccessStatusCode();
        }

        public async Task<HttpResponseMessage> Get(int userId, string url)
        {
            var httpClient = await GetClient(userId);
            var rm = await httpClient.GetAsync(url);
            RaiseGraphAccessTokenExpiredException(rm);

            return rm;
        }

        static void RaiseGraphAccessTokenExpiredException(HttpResponseMessage rm)
        {
            if (rm.StatusCode != HttpStatusCode.Unauthorized) return;

            throw new GraphAccessTokenExpiredException(HttpStatusCode.Unauthorized.ToString());
        }
    }
}
