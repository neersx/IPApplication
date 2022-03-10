using System;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Policing;

namespace Inprotech.Web.Policing
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.PolicingAdministration)]
    [RoutePrefix("api/policing/queue/admin")]
    public class PolicingQueueAdministrationController : ApiController
    {
        readonly ICommonQueryService _commonQueryService;
        readonly IPolicingQueue _policingQueue;
        readonly IUpdatePolicingRequest _updatePolicingRequest;

        public PolicingQueueAdministrationController(IPolicingQueue policingQueue, ICommonQueryService commonQueryService,
                                                     IUpdatePolicingRequest updatePolicingRequest)
        {
            _policingQueue = policingQueue;
            _commonQueryService = commonQueryService;
            _updatePolicingRequest = updatePolicingRequest;
        }

        [HttpPut]
        [Route("release/{byStatus}")]
        public void ReleaseAllPolicingRequests(string byStatus, CommonQueryParameters queryParameters)
        {
            var selectedItems = GetRequestedIds(byStatus, queryParameters);
            ReleasePolicingRequests(selectedItems);
        }

        [HttpPost]
        [Route("release")]
        public void ReleasePolicingRequests(int[] selectedItems)
        {
            _updatePolicingRequest.Release(selectedItems);
        }

        [HttpPut]
        [Route("hold/{byStatus}")]
        [RequiresAccessTo(ApplicationTask.PolicingAdministration)]
        public void HoldAllPolicingRequests(string byStatus, CommonQueryParameters queryParameters)
        {
            var selectedItems = GetRequestedIds(byStatus, queryParameters);
            HoldPolicingRequests(selectedItems);
        }

        [HttpPost]
        [Route("hold")]
        public void HoldPolicingRequests(int[] selectedItems)
        {
            _updatePolicingRequest.Hold(selectedItems);
        }

        [HttpPost]
        [Route("delete/{byStatus}")]
        public void DeleteAllPolicingRequests(string byStatus, CommonQueryParameters queryParameters )
        {
            var selectedItems = GetRequestedIds(byStatus, queryParameters);
            DeletePolicingRequests(selectedItems);
        }

        [HttpPost]
        [Route("delete")]
        public void DeletePolicingRequests(int[] selectedItems)
        {
            _updatePolicingRequest.Delete(selectedItems);
        }

        [HttpPost]
        [Route("editNextRuntTime/{nextRunTime}")]
        public void EditNextRunTime(string nextRunTime,int[] selectedItems)
        {
            _updatePolicingRequest.EditNextRunTime(DateTime.Parse(nextRunTime), selectedItems);
        }

        int[] GetRequestedIds(string byStatus, CommonQueryParameters queryParameters)
        {
            return _commonQueryService.
                Filter(_policingQueue.Retrieve(byStatus), PolicingQueueQueryParameters.Get(queryParameters))
                                      .Select(_ => _.RequestId)
                                      .ToArray();
        }
    }
}