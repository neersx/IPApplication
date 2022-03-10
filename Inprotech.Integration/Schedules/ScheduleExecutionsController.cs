using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Extensions;

namespace Inprotech.Integration.Schedules
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleIpOneDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleFileDataDownload)]
    [NoEnrichment]
    public class ScheduleExecutionsController : ApiController
    {
        readonly IScheduleExecutions _scheduleExecutions;

        public ScheduleExecutionsController(IScheduleExecutions scheduleExecutions)
        {
            _scheduleExecutions = scheduleExecutions;
        }

        [HttpGet]
        [Route("api/ptoaccess/schedules/{scheduleId:int}/scheduleExecutions/view")]
        public async Task<PagedResults> Get(int scheduleId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                            CommonQueryParameters queryParams = null)
        {
            if (queryParams == null)
            {
                queryParams = new CommonQueryParameters { Take = 50 };
            }

            return await _scheduleExecutions.Get(scheduleId).AsPagedResultsAsync(queryParams);
        }

        [HttpGet]
        [Route("api/ptoaccess/schedules/{scheduleId:int}/scheduleExecutions")]
        public IEnumerable<dynamic> Get(int scheduleId, ScheduleExecutionStatus? status)
        {
            return _scheduleExecutions.Get(scheduleId, status).Take(30).ToArray();
        }

        [HttpGet]
        [Route("api/ptoaccess/schedules/{scheduleId:int}/scheduleExecutions/{executionId:int}/raw-index")]
        public HttpResponseMessage RawExecutionIndex(int scheduleId, long executionId)
        {
            var r = _scheduleExecutions.Get(scheduleId)
                                       .SingleOrDefault(_ => _.Id == executionId);

            if (r == null || !r.AllowsIndexRetrieval)
            {
                return new HttpResponseMessage(HttpStatusCode.BadRequest);
            }

            var response = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StreamContent(new MemoryStream(r.IndexList))
            };

            response.Content.Headers.ContentType = new MediaTypeHeaderValue("application/zip");

            response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
                                                          {
                                                              FileName = "index-list.zip"
                                                          };

            return response;
        }
    }
}