using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Infrastructure.Security
{
    public class UserIdentityAccessData
    {
        public UserIdentityAccessData()
        {
            
        }
        public UserIdentityAccessData(string sessionId, string accessToken, string refreshToken)
        {
            SessionId = sessionId;
            AccessToken = accessToken;
            RefreshToken = refreshToken;
        }
        public string RefreshToken { get; set; }

        public string AccessToken { get; set; }

        public string SessionId { get; set; }

        public override string ToString()
        {
            var jObject = JObject.FromObject(this, new JsonSerializer { NullValueHandling = NullValueHandling.Ignore });
            return jObject.ToString();
        }
    }
}