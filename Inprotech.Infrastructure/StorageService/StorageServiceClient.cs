using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Monitoring;
using Inprotech.Infrastructure.Web;
using Newtonsoft.Json;

namespace Inprotech.Infrastructure.StorageService
{
    public class StorageServiceClient : IStorageServiceClient
    {
        readonly Uri _baseStorageServiceUrl;
        readonly ICurrentOperationIdProvider _currentOperationIdProvider;
        readonly ISessionAccessTokenGenerator _sessionAccessTokenGenerator;
        public readonly IValidateHttpOrHttpsString _validateHttpOrHttpsString;

        public StorageServiceClient(IAppSettingsProvider appSettingsProvider,
                                    ICurrentOperationIdProvider currentOperationIdProvider,
                                    ISessionAccessTokenGenerator sessionAccessTokenGenerator, IValidateHttpOrHttpsString validateHttpOrHttpsString)
        {
            _currentOperationIdProvider = currentOperationIdProvider;
            _sessionAccessTokenGenerator = sessionAccessTokenGenerator;
            _validateHttpOrHttpsString = validateHttpOrHttpsString;
            _baseStorageServiceUrl = new Uri(appSettingsProvider["StorageServiceBaseUrl"]);
        }

        public async Task<bool> ValidatePath(string path, HttpRequestMessage request)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException(nameof(path));

            var url = $"api/validatePath?path={HttpUtility.UrlEncode(path)}";

            var response = await GetResponse<dynamic>(url);
            var data = await response.Content.ReadAsStringAsync();

            if (!string.IsNullOrWhiteSpace(data) && bool.TryParse(data, out var result))
            {
                return result;
            }

            return false;
        }

        public async Task<DirectoryValidationResult> ValidateDirectory(string path, HttpRequestMessage request)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException(nameof(path));

            var url = $"api/validateDirectory?path={HttpUtility.UrlEncode(path)}";

            var response = await GetResponse<dynamic>(url);
            var data = await response.Content.ReadAsStringAsync();

            if (!string.IsNullOrWhiteSpace(data))
            {
                var result = JsonConvert.DeserializeObject<DirectoryValidationResult>(data);
                return result;
            }

            return new DirectoryValidationResult();
        }

        public async Task RefreshCache<T>(HttpRequestMessage request, T attachmentSettings)
        {
            var url = "api/refresh";

            await GetResponse(url, HttpMethod.Post, attachmentSettings);
        }

        public async Task<HttpResponseMessage> GetDirectoryFolders(HttpRequestMessage request)
        {
            var response = await GetResponse<dynamic>("api/directory");
            return response;
        }

        public async Task<HttpResponseMessage> GetDirectoryFiles(string path, HttpRequestMessage request)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException(nameof(path));

            var response = await GetResponse<dynamic>($"api/files?path={HttpUtility.UrlEncode(path)}");
            return response;
        }

        public async Task<HttpResponseMessage> UploadFile(HttpRequestMessage request)
        {
            var url = new Uri(_baseStorageServiceUrl, "api/uploadFile");

            using (var handler = new HttpClientHandler())
            using (var client = new HttpClient(handler) {BaseAddress = url})
            using (var message = await CreateApiKeyProtectedMessage(HttpMethod.Post, url))
            {
                message.Content = request.Content;
                foreach (var prop in request.Properties) message.Properties.Add(prop);

                foreach (var header in request.Headers) message.Headers.TryAddWithoutValidation(header.Key, header.Value);

                var response = await client.SendAsync(message);
                return response;
            }
        }

        public async Task<HttpResponseMessage> GetFile(int activityKey, int? sequenceKey, string path, HttpRequestMessage request)
        {
            if (_validateHttpOrHttpsString.Validate(path))
            {
                var redirectResponse = request.CreateResponse(HttpStatusCode.Redirect);
                redirectResponse.Headers.Location = new Uri(path);
                return redirectResponse;
            }

            var response = await GetResponse<dynamic>($"api/file?path={HttpUtility.UrlEncode(path)}");
            return response;
        }

        async Task<HttpResponseMessage> GetResponse<T>(string api, HttpMethod method = null, T value = default(T))
        {
            var url = new Uri(_baseStorageServiceUrl, api);

            using (var handler = new HttpClientHandler {UseCookies = false})
            using (var client = new HttpClient(handler) {BaseAddress = url})
            using (var request = await CreateApiKeyProtectedMessage(method ?? HttpMethod.Get, url))
            {
                if (method == HttpMethod.Put || method == HttpMethod.Post)
                {
                    request.Content = new ObjectContent<T>(value, new JsonMediaTypeFormatter());
                }

                client.NoTimeout();

                var response = await client.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                {
                    throw new HttpRequestException(
                                                   $"Response status code does not indicate success: {(int) response.StatusCode}");
                }

                return response;
            }
        }

        async Task<HttpRequestMessage> CreateApiKeyProtectedMessage(HttpMethod method, Uri api)
        {
            var message = new HttpRequestMessage(method, api);

            message.Headers.Add("X-ApiKey", (await _sessionAccessTokenGenerator.GetOrCreateAccessToken()).ToString());
            message.Headers.Add(OperationContexts.RequestIdHeader, _currentOperationIdProvider.OperationId);

            return message;
        }
    }
}