using System.Web.Http;

namespace Inprotech.Integration.Qos
{
    public class StatusController : ApiController
    {
        [Route("api/integrationserver/status")]
        public string Get()
        {
            return "Awake";
        }
    }
}