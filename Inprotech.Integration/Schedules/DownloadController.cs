using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Diagnostics.PtoAccess;

namespace Inprotech.Integration.Schedules
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleIpOneDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleFileDataDownload)]
    public class DownloadController : ApiController
    {
        readonly IDiagnosticLogsProvider _diagnosticLogsProvider;

        public DownloadController(IDiagnosticLogsProvider diagnosticLogsProvider)
        {
            _diagnosticLogsProvider = diagnosticLogsProvider;
        }

        [HttpGet]
        [Route("api/ptoaccess/diagnostics/download-logs")]
        public async Task<HttpResponseMessage> Export()
        {
            if (!_diagnosticLogsProvider.DataAvailable)
                return new HttpResponseMessage(HttpStatusCode.BadRequest);

            var response = new HttpResponseMessage(HttpStatusCode.OK)
                           {
                               Content = new StreamContent(await _diagnosticLogsProvider.Export())
                           };

            response.Content.Headers.ContentType = new MediaTypeHeaderValue("application/zip");

            response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment") {FileName = "Diagnostics.Logs.zip"};

            return response;
        }
    }
}