using System;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Integration.Settings;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Epo
{
    public interface IEpoAuthClient
    {
        Task<string> GetAccessToken();

        Task<bool> TestSettings(EpoKeys epoKeys);
    }

    public class EpoAuthClient : IEpoAuthClient
    {
        readonly IEpoSettings _epoSettings;

        public EpoAuthClient(IEpoSettings epoSettings)
        {
            _epoSettings = epoSettings;
        }

        public async Task<bool> TestSettings(EpoKeys epoKeys)
        {
            var token = await GetAccessToken(epoKeys.ConsumerKey, epoKeys.PrivateKey);
            return !string.IsNullOrWhiteSpace(token);
        }

        public async Task<string> GetAccessToken()
        {
            _epoSettings.EnsureRequiredKeysAvailable();

            return await GetAccessToken(_epoSettings.EpoConsumerKey, _epoSettings.EpoConsumerPrivateKey);
        }

        async Task<string> GetAccessToken(string consumerKey, string privateKey)
        {
            string token = null;
            var request = (HttpWebRequest)WebRequest.Create(_epoSettings.EpoAuthUrl);
            request.Method = "POST";
            request.ContentType = "application/x-www-form-urlencoded";
            request.Headers["Authorization"] = "Basic " + Convert.ToBase64String(Encoding.ASCII.GetBytes(consumerKey + ":" + privateKey));

            using (var writer = new StreamWriter(request.GetRequestStream()))
                writer.Write("grant_type=client_credentials");

            try
            {
                var response = await request.GetResponseAsync();

                var stream = response.GetResponseStream();
                if (stream != null)
                {
                    var reader = new StreamReader(stream);
                    var result = await reader.ReadToEndAsync();
                    try
                    {
                        token = (string)JObject.Parse(result)["access_token"];
                    }
                    catch (Exception ex)
                    {
                        throw new EpoAuthInvalidResponse(result, ex);
                    }
                }
            }
            catch (WebException ex)
            {
                var response = ex.Response as HttpWebResponse;

                if (response == null)
                    throw;

                var statusCode = response.StatusCode;
                if (statusCode == HttpStatusCode.Unauthorized)
                {
                    throw new EpoAuthUnauthorizedResponse(ex);
                }

                if (statusCode == HttpStatusCode.Forbidden)
                {
                    throw new EpoAuthForbiddenResponse(ex);
                }
                throw;
            }
            return token;
        }
    }
}
