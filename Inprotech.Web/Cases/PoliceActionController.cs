using System;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Policing;

namespace Inprotech.Web.Cases
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/cases/policeAction")]
    public class PoliceActionController : ApiController
    {
        readonly IPolicingEngine _policingEngine;
        readonly ISiteControlReader _siteControlReader;

        public PoliceActionController(IPolicingEngine policingEngine, ISiteControlReader siteControlReader)
        {
            _policingEngine = policingEngine;
            _siteControlReader = siteControlReader;
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.PoliceActionsOnCase)]
        [RequiresCaseAuthorization(PropertyPath = "request.CaseId")]
        public async Task<dynamic> PoliceAnAction(PoliceActionModel request)
        {
            var isPolicingImmediate = request.IsPoliceImmediately ?? _siteControlReader.Read<bool>(SiteControls.PoliceImmediately);

            var policingQueueResult = _policingEngine.QueueOpenActionRequest(request.CaseId, request.ActionId, request.Cycle, isPolicingImmediate);

            if (isPolicingImmediate)
            {
                if (!policingQueueResult.PolicingBatchNumber.HasValue)
                {
                    throw new Exception("Policing batch no not supplied");
                }
                return _policingEngine.Police(policingQueueResult.PolicingBatchNumber);
            }

            return policingQueueResult;
        }

        public class PoliceActionModel
        {
            public int CaseId { get; set; }
            public string ActionId { get; set; }
            public int Cycle { get; set; }
            public bool? IsPoliceImmediately { get; set; }
        }
    }
}
