using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography
{
    public class InnographyRequestMessage
    {
        readonly Func<DateTime> _now;

        public InnographyRequestMessage(Func<DateTime> now)
        {
            _now = now;
        }

        public async Task<HttpRequestMessage> Create(HttpMethod method, Uri api, string username,
                                                     string secret,
                                                     string version,
                                                     string hmacCryptoAlgorithm,
                                                     dynamic data = null)
        {
            var now = _now();
            var request = new HttpRequestMessage(method, api);
            var serialised = data == null
                ? "[]"
                : JsonConvert.SerializeObject(data, new JsonSerializerSettings
                {
                    NullValueHandling = NullValueHandling.Ignore
                });
            var content = new StringContent(serialised, Encoding.UTF8, "application/json");

            using (var md5 = MD5.Create())
            using (var contentStream = await content.ReadAsStreamAsync())
            {
                content.Headers.ContentMD5 = md5.ComputeHash(contentStream);
            }

            request.Method = method;
            request.Headers.Date = new DateTimeOffset(now, TimeZoneInfo.Local.GetUtcOffset(now));
            request.Content = content;

            var signingString = "Date: " + request.Headers.Date.Value.ToString("R") + '\n' +
                                "Content-MD5: " + Convert.ToBase64String(content.Headers.ContentMD5);

            string signature;
            var keyByte = Encoding.ASCII.GetBytes(secret);
            using (var hmac = CryptoAlgorithmFactory(hmacCryptoAlgorithm, keyByte))
            {
                var messageBytes = Encoding.ASCII.GetBytes(signingString);
                var hashMessage = hmac.ComputeHash(messageBytes);
                signature = Convert.ToBase64String(hashMessage);
            }

            request.Headers.Add("Accept", $"application/vnd.innography+json;version={version}");
            request.Headers.Add("Client-ID", username);
            request.Headers.Authorization = new AuthenticationHeaderValue("hmac",
                                                                          $"username=\"{username}\", algorithm=\"{hmacCryptoAlgorithm}\", headers=\"Date Content-MD5\", signature=\"{signature}\"");
            
            return request;
        }

        public HttpRequestMessage CreateForNonContentMethod(HttpMethod method, Uri api, string username,
                                                     string secret,
                                                     string version)
        {
            var now = _now();
            var request = new HttpRequestMessage(method, api) {Method = method};

            request.Headers.Date = new DateTimeOffset(now, TimeZoneInfo.Local.GetUtcOffset(now));
            
            var signingString = "Date: " + request.Headers.Date.Value.ToString("R") + '\n' +
                                "Content-MD5: 11FxOYiYfpMxmANj4kGJzg==";

            string signature;
            var keyByte = Encoding.ASCII.GetBytes(secret);
            using (var hmac = new HMACSHA1(keyByte))
            {
                var messageBytes = Encoding.ASCII.GetBytes(signingString);
                var hashmessage = hmac.ComputeHash(messageBytes);
                signature = Convert.ToBase64String(hashmessage);
            }

            request.Headers.Add("Accept", $"application/vnd.innography+json;version={version}");
            request.Headers.Add("Client-ID", username);
            request.Headers.Authorization = new AuthenticationHeaderValue("hmac",
                                                                          $"username=\"{username}\", algorithm=\"hmac-sha1\", headers=\"Date Content-MD5\", signature=\"{signature}\"");
            
            var invalidHeaders = (HashSet<string>)typeof(HttpHeaders)
                .GetField("invalidHeaders", BindingFlags.NonPublic | BindingFlags.Instance)
                .GetValue(request.Headers);
            invalidHeaders.Remove("Content-Type");
            invalidHeaders.Remove("Content-MD5");
            
            request.Headers.Remove("Content-Type");
            request.Headers.Remove("Content-MD5");
            request.Headers.Add("Content-Type", "application/json");
            request.Headers.Add("Content-MD5", "11FxOYiYfpMxmANj4kGJzg==");

            invalidHeaders.Add("Content-Type");
            invalidHeaders.Add("Content-MD5");

            return request;
        }

        static HMAC CryptoAlgorithmFactory(string requestedAlgorithm, byte[] keyBytes)
        {
            if (requestedAlgorithm == CryptoAlgorithm.Sha256)
                return new HMACSHA256(keyBytes);

            if (requestedAlgorithm == CryptoAlgorithm.Sha1)
                return new HMACSHA1(keyBytes);

            throw new Exception("Cannot create requested crypto algorithm");
        }
    }
}