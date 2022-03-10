using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security.External;
using Microsoft.Rest;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Infrastructure.Security.External
{
    public class CredentialTokens
    {
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
        public bool OAuth2 { get; set; }
    }

    public class OAuthTokenResponse
    {
        [JsonProperty("token_type")]
        public string TokenType { get; set; }

        [JsonProperty("expires_in")]
        public int ExpiresIn { get; set; }

        [JsonProperty("refresh_token")]
        public string RefreshToken { get; set; }

        [JsonProperty("access_token")]
        public string AccessToken { get; set; }
    }
}

namespace Inprotech.Integration.DmsIntegration.Component.iManage.v10
{
    public interface IWorkServerClient
    {
        Task<Response<string>> Send(HttpMethod method, string context, Uri uri, dynamic data = null);
        Task<Response<byte[]>> Download(string context, Uri uri);
        Task<bool> Login(Uri loginEndpoint, string userName, string password, bool force = false);
        Task Logout(Uri logoutEndpoint);
    }

    public class WorkServerClient : IWorkServerClient
    {
        const string LoginContext = "login";
        const string LogoutContext = "logout";
        const string IncludeBearerTokenKey = "iManage.OAuth2.IncludeBearerToken";

        readonly IAccessTokenManager _accessTokenManager;
        readonly bool _includeBearerToken;

        public WorkServerClient(IAccessTokenManager accessTokenManager, Func<string, IGroupedConfig> groupedConfig)
        {
            _accessTokenManager = accessTokenManager;
            var config = groupedConfig("DMSIntegration");
            _includeBearerToken = config.GetValueOrDefault(IncludeBearerTokenKey, "false") == "true";
        }

        public async Task<bool> Login(Uri loginEndpoint, string userName, string password, bool force = false)
        {
            var accessToken = await _accessTokenManager.GetToken(userName);

            if (accessToken == null || force)
            {
                if (force)
                {
                    _accessTokenManager.SetStoredTokens(null);
                }

                var r = await Send(HttpMethod.Put, LoginContext, loginEndpoint, new
                {
                    application_name = "Inprotech",
                    user_id = userName,
                    password,
                    persona = "user"
                });

                if (r.StatusCode == HttpStatusCode.Unauthorized || string.IsNullOrWhiteSpace(r.Data))
                {
                    return false;
                }

                var loginData = JObject.Parse(r.Data);
                _accessTokenManager.SetStoredTokens(new CredentialTokens
                {
                    AccessToken = (string) loginData["X-Auth-Token"],
                    OAuth2 = false
                });

                if (_accessTokenManager.GetStoredTokens() != null)
                {
                    //LifeTimeDictionaryToken.AddOrUpdate(key, _token, (k, v) => _token);
                    await _accessTokenManager.SaveToken(_accessTokenManager.GetStoredTokens(), userName);
                }
            }
            else
            {
                _accessTokenManager.SetStoredTokens(accessToken);
            }

            return _accessTokenManager.GetStoredTokens() != null;
        }

        public async Task Logout(Uri logoutEndpoint)
        {
            if (_accessTokenManager.GetStoredTokens() == null) return;

            await Send(HttpMethod.Put, LogoutContext, logoutEndpoint);
        }

        public async Task<Response<string>> Send(HttpMethod method, string context, Uri uri, dynamic data = null)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (uri == null) throw new ArgumentNullException(nameof(uri));
            var token = _accessTokenManager.GetStoredTokens();
            using (var handler = new HttpClientHandler {UseCookies = false})
            using (var client = new HttpClient(handler) {BaseAddress = uri})
            using (var request = new HttpRequestMessage(method, uri))
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();

                ServiceClientTracing.Enter(invocationId, this, context, new Dictionary<string, object>());
                if (!string.IsNullOrWhiteSpace(token?.AccessToken))
                {
                    if (token.OAuth2)
                    {
                        request.Headers.Add("X-Auth-Token", token.AccessToken);
                    }

                    if (!token.OAuth2 || _includeBearerToken)
                    {
                        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.AccessToken);
                    }
                }

                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                if (data != null)
                {
                    var payLoad = JsonConvert.SerializeObject(data, new JsonSerializerSettings
                    {
                        ContractResolver = new DefaultContractResolver
                        {
                            NamingStrategy = new CamelCaseNamingStrategy()
                        },
                        NullValueHandling = NullValueHandling.Ignore
                    });
                    request.Content = new StringContent(payLoad, Encoding.UTF8, "application/json");
                }

                ServiceClientTracing.SendRequest(invocationId, request);

                using (var response = await client.SendAsync(request, HttpCompletionOption.ResponseContentRead))
                {
                    ServiceClientTracing.ReceiveResponse(invocationId, response);
                    if (response.Content != null)
                    {
                        var statusCode = response.StatusCode;
                        var jsonData = await response.Content.ReadAsStringAsync();

                        if (!response.IsSuccessStatusCode)
                        {
                            if (response.StatusCode == HttpStatusCode.Unauthorized && context != LoginContext)
                            {
                                throw new CachedTokenExpiredException();
                            }

                            ServiceClientTracing.Error(invocationId,
                                                       new HttpOperationException(
                                                                                  $"Operation returned an invalid status code '{response.StatusCode}'")
                                                       {
                                                           Request = new HttpRequestMessageWrapper(request, null),
                                                           Response = new HttpResponseMessageWrapper(response, jsonData)
                                                       });

                            if (response.StatusCode != HttpStatusCode.Unauthorized)
                            {
                                if (response.StatusCode == HttpStatusCode.NotFound && !string.IsNullOrWhiteSpace(jsonData))
                                {
                                    var exception = JsonConvert.DeserializeObject<ErrorResponse>(jsonData);
                                    if (exception?.Error?.Code == "NRC_NO_RECORD")
                                    {
                                        return new Response<string>
                                        {
                                            StatusCode = HttpStatusCode.OK,
                                            Data = string.Empty
                                        };
                                    }
                                }

                                var error = JObject.Parse(jsonData ?? "{}");
                                throw new HttpRequestException(
                                                               $"Response status code does not indicate success: {(int) statusCode} ({response.ReasonPhrase}) - {error["message"]}");
                            }

                            return new Response<string>
                            {
                                StatusCode = statusCode
                            };
                        }

                        ServiceClientTracing.Exit(invocationId, jsonData);
                        return new Response<string>
                        {
                            StatusCode = statusCode,
                            Data = jsonData
                        };
                    }
                }
            }

            return new Response<string> {StatusCode = HttpStatusCode.OK};
        }

        public async Task<Response<byte[]>> Download(string context, Uri uri)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (uri == null) throw new ArgumentNullException(nameof(uri));
            var token = _accessTokenManager.GetStoredTokens();
            using (var handler = new HttpClientHandler {UseCookies = false})
            using (var client = new HttpClient(handler) {BaseAddress = uri})
            using (var request = new HttpRequestMessage(HttpMethod.Get, uri))
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();

                ServiceClientTracing.Enter(invocationId, this, context, new Dictionary<string, object>());

                if (!string.IsNullOrWhiteSpace(token?.AccessToken))
                {
                    if (token.OAuth2)
                    {
                        request.Headers.Add("x-Auth-Token", token.AccessToken);
                    }
                    else
                    {
                        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.AccessToken);
                    }
                }

                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

                ServiceClientTracing.SendRequest(invocationId, request);

                using (var response = await client.SendAsync(request, HttpCompletionOption.ResponseContentRead))
                {
                    ServiceClientTracing.ReceiveResponse(invocationId, response);

                    if (response.Content != null)
                    {
                        var statusCode = response.StatusCode;

                        if (!response.IsSuccessStatusCode)
                        {
                            if (response.StatusCode == HttpStatusCode.Unauthorized)
                            {
                                throw new CachedTokenExpiredException();
                            }

                            ServiceClientTracing.Error(invocationId,
                                                       new HttpOperationException(
                                                                                  $"Operation returned an invalid status code '{response.StatusCode}'")
                                                       {
                                                           Request = new HttpRequestMessageWrapper(request, null),
                                                           Response = new HttpResponseMessageWrapper(response, null)
                                                       });

                            var jsonData = await response.Content.ReadAsStringAsync();
                            var error = JObject.Parse(jsonData);
                            throw new HttpRequestException(
                                                           $"Response status code does not indicate success: {(int) statusCode} ({response.ReasonPhrase}) - {error["message"]}");
                        }

                        var byteArray = await response.Content.ReadAsByteArrayAsync();
                        ServiceClientTracing.Exit(invocationId, null);
                        return new Response<byte[]>
                        {
                            StatusCode = statusCode,
                            Data = byteArray
                        };
                    }
                }
            }

            return new Response<byte[]> {StatusCode = HttpStatusCode.OK};
        }
    }

    public class Response<T>
    {
        public HttpStatusCode StatusCode { get; set; }

        public T Data { get; set; }
    }

    public class ErrorResponse
    {
        [JsonProperty("error")]
        public ErrorDetails Error { get; set; }

        public class ErrorDetails
        {
            [JsonProperty("code")]
            public string Code { get; set; }

            [JsonProperty("code_message")]
            public string CodeMessage { get; set; }
        }
    }
}