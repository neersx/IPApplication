using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using InprotechKaizen.Model.Components.Policing;

namespace Inprotech.Web.Cases
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/cases/policeBatch")]
    public class PoliceBatchController : ApiController
    {
        readonly IPolicingEngine _policingEngine;

        public PoliceBatchController(IPolicingEngine policingEngine)
        {
            _policingEngine = policingEngine;
        }

        [HttpPost]
        [Route("")]
        public async Task<dynamic> PoliceBatch(PoliceBatchModel request)
        {
            return _policingEngine.Police(request.BatchNo);
        }

        public class PoliceBatchModel
        {
            public int BatchNo { get; set; }
        }
    }
}
