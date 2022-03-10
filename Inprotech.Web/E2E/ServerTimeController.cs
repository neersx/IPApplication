using System;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security.ExternalApplications;

namespace Inprotech.Web.E2E
{
    [RequiresApiKey(ExternalApplicationName.E2E)]
    public class ServerTimeController : ApiController
    {
        [HttpGet]
        [NoEnrichment]
        [Route("api/e2e/serverTimeUtc")]
        public object GetCurrentUtcTime()
        {
            return new
            {
                Value = DateTime.UtcNow.Ticks.ToString()
            };
        }
    }
}
