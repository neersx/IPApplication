using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [ViewInitialiser]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create)]
    public class PriorArtEditViewController : ApiController
    {
        [HttpGet]
        [Route("api/priorart/priorarteditview")]
        public dynamic Get()
        {
            return null;
        }
    }
}