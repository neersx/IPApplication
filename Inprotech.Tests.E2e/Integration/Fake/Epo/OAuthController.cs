using System.Web.Http;

namespace Inprotech.Tests.E2e.Integration.Fake.Epo
{
    public class OAuthController : ApiController
    {
        [HttpPost]
        [Route("integration/epo/auth/accesstoken")]
        public dynamic AccessToken()
        {
            return new
                   {
                       access_token = "fake"
                   };
        }
    }
}
