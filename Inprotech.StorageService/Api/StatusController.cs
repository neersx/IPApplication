using System.Web.Http;

namespace Inprotech.StorageService.Api
{
    public class StatusController : ApiController
    {
        [Route("api/storageservice/status")]
        public string Get()
        {
            return "Awake";
        }
    }
}