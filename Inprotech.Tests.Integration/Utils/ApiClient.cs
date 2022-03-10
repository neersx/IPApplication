using System;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Web.Security;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.AntiForgery;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using TestUtilApiClientException = Inprotech.Tests.Integration.Utils.ApiClientException;

namespace Inprotech.Tests.Integration.Utils
{
    [SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    public class ApiClientException : Exception
    {
        public ApiClientException(string uri, WebException ex)
        {
            var context = Environment.NewLine + uri + Environment.NewLine;
            var response = ex.Response;
            var responseBody = string.Empty;
            using var stream = response.GetResponseStream();
            if (stream != null)
            {
                var reader = new StreamReader(stream);
                responseBody = reader.ReadToEnd();

                if (!string.IsNullOrWhiteSpace(responseBody))
                {
                    responseBody = Environment.NewLine + responseBody;
                }
            }

            Message = context + ex.Message + responseBody;
        }

        public override string Message { get; }
    }

    public static class ApiClient
    {
        static long CreateAccessLogEntry(int userId)
        {
            var dbContext = new SqlDbContext();
            var log = new UserIdentityAccessLog(userId, "Forms", "E2E Api Call", DateTime.Now);
            dbContext.Set<UserIdentityAccessLog>().Add(log);
            dbContext.SaveChanges();

            return log.LogId;
        }

        public static T Get<T>(string apiEndpoint, string username = null, int? loginUserId = null)
        {
            var request = BuildApiRequest(apiEndpoint, username ?? Env.LoginUsername, loginUserId ?? Env.LoginUserId);
            
            request.Method = "GET";
            
            using var response = GetResponse(request);
            
            return DeserializeResponse<T>(response);
        }

        public static T GetExternal<T>(string apiEndPoint, string username = null, int? loginUserId = null)
        {
            return Get<T>(apiEndPoint, username ?? Env.ExternalLoginUsername, loginUserId ?? Env.ExternalLoginUserId);
        }

        public static HttpWebResponse GetResponse(string apiEndpoint, string username = null, int? loginUserId = null)
        {
            var request = BuildApiRequest(apiEndpoint, username ?? Env.LoginUsername, loginUserId ?? Env.LoginUserId);

            request.Method = "GET";

            return GetResponse(request);
        }

        public static HttpStatusCode Delete(string apiEndpoint, string username = null, int? loginUserId = null)
        {
            var request = BuildApiRequest(apiEndpoint, username ?? Env.LoginUsername, loginUserId ?? Env.LoginUserId);

            request.Method = "DELETE";
            
            using var response = GetResponse(request);

            return response.StatusCode;
        }

        public static void Put(string apiEndpoint, string body, string username = null, int? loginUserId = null)
        {
            using (CallPut(apiEndpoint, body, username ?? Env.LoginUsername, loginUserId ?? Env.LoginUserId))
            {
            }
        }

        public static void Put(string apiEndpoint, dynamic body, string username = null, int? loginUserId = null)
        {
            using (CallPut(apiEndpoint, ToJson(body), username ?? Env.LoginUsername, loginUserId ?? Env.LoginUserId))
            {
            }
        }

        public static T Post<T>(string apiEndpoint, dynamic body, string username = null, int? loginUserId = null)
        {
            using var response = CallPost(apiEndpoint, ToJson(body), username ?? Env.LoginUsername, loginUserId ?? Env.LoginUserId);
            
            return DeserializeResponse<T>(response);
        }

        public static T Post<T>(string apiEndpoint, string body, string username = null, int? loginUserId = null)
        {
            using var response = CallPost(apiEndpoint, body, username ?? Env.LoginUsername, loginUserId ?? Env.LoginUserId);
            
            return DeserializeResponse<T>(response);
        }

        public static (HttpWebResponse response, string stringResult) Post(string apiEndpoint, string body, string username = null, int? loginUserId = null)
        {
            var response = CallPost(apiEndpoint, string.Empty, username ?? Env.LoginUsername, loginUserId ?? Env.LoginUserId);
            
            return (response, DeserializeResponse<string>(response));
        }

        public static T Put<T>(string apiEndpoint, string body, string username = null, int? loginUserId = null)
        {
            using var response = CallPut(apiEndpoint, body, username ?? Env.LoginUsername, loginUserId ?? Env.LoginUserId);
            
            return DeserializeResponse<T>(response);
        }

        static HttpWebResponse CallPut(string apiEndpoint, string body, string username, int loginUserId)
        {
            var request = BuildApiRequest(apiEndpoint, username, loginUserId);

            request.Method = "PUT";
            request.ContentType = "application/json";

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
                throw new TestUtilApiClientException($"PUT {request.RequestUri.PathAndQuery}", ex);
            }
        }

        static HttpWebResponse CallPost(string apiEndpoint, string body, string username, int loginUserId)
        {
            var request = BuildApiRequest(apiEndpoint, username, loginUserId);

            request.Method = "POST";
            request.ContentType = "application/json";

            using (var writer = new StreamWriter(request.GetRequestStream()))
            {
                writer.Write(body);
            }

            var response = GetResponse(request);
            return response;
        }

        static HttpWebRequest BuildApiRequest(string apiEndpoint, string username, int loginUserId)
        {
            var logId = CreateAccessLogEntry(loginUserId);
            var userData = new AuthCookieData(new AuthUser(username, loginUserId, "Forms", logId), false);

            var ticket = FormsAuthentication.Encrypt(new FormsAuthenticationTicket(1, username, DateTime.Now, DateTime.Now.AddMinutes(10), true, JsonConvert.SerializeObject(userData)));
            var apiUrl = new Uri(new Uri(Env.RootUrl), "apps/api/" + apiEndpoint);

            var csrfToken = AntiForgeryToken.Generate(ticket);

            var request = (HttpWebRequest) WebRequest.Create(apiUrl);
            request.Headers.Add(CsrfConfigOptions.HeaderName, csrfToken);

            if (System.Diagnostics.Debugger.IsAttached)
            {
                request.Timeout = -1;
            }

            var cookieContainer = new CookieContainer();
            cookieContainer.Add(new Cookie(".CPASSInprotech", ticket, "/", apiUrl.Host));
            cookieContainer.Add(new Cookie(CsrfConfigOptions.CookieName, csrfToken, "/", apiUrl.Host));
            request.CookieContainer = cookieContainer;
            return request;
        }

        static T DeserializeResponse<T>(HttpWebResponse response)
        {
            using var reader = new StreamReader(response.GetResponseStream());
            
            var str = reader.ReadToEnd();

            if (typeof(T) == typeof(string))
            {
                return (T) (object) str;
            }

            if (typeof(T) == typeof(HttpResponseMessage))
            {
                return (T)(object) new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent(str, Encoding.UTF8, "application/json")
                };
            }

            return JsonConvert.DeserializeObject<T>(str);
        }

        static HttpWebResponse GetResponse(HttpWebRequest request)
        {
            try
            {
                return (HttpWebResponse) request.GetResponse();
            }
            catch (WebException ex)
            {
                throw new TestUtilApiClientException($"{request.Method} {request.RequestUri.PathAndQuery}", ex);
            }
        }
        
        static string ToJson(dynamic o)
        {
            return JObject.FromObject(o).ToString();
        }

        static string ToJson(dynamic[] o)
        {
            return JArray.FromObject(o).ToString();
        }
    }
}