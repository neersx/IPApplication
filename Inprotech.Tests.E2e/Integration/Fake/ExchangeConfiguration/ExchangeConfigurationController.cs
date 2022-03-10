using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace Inprotech.Tests.E2e.Integration.Fake.ExchangeConfiguration
{
    [RoutePrefix("exchange/configuration")]
    public class ExchangeConfigurationController : ApiController
    {
        [HttpGet]
        [Route("test/{version}/{user}/{feature}")]
        public HttpResponseMessage Get(string version, string user, string feature)
        {
            return new HttpResponseMessage(HttpStatusCode.OK);
        }
    }
}
