using System;
using System.Threading.Tasks;
using System.Web.Http;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.ContentManagement;
using InprotechKaizen.Model.Components.Reporting;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Reports
{
    public interface IReportsController
    {
        Task<ProviderInfo> GetReportProviderInfo();

        Task<int> GenerateBillingWorkSheet(JObject criteria);
    }

    [Authorize]
    [RoutePrefix("api/reports")]
    public class ReportsController : ApiController, IReportsController
    {
        readonly IBus _bus;
        readonly IExportContentService _exportContentService;
        readonly ILogger<ReportsController> _logger;
        readonly IIndex<string, IReportsManager> _reportManagerMap;
        readonly IReportProvider _reportProvider;

        public ReportsController(IReportProvider reportProvider, IExportContentService exportContentService, IBus bus, ILogger<ReportsController> logger, IIndex<string, IReportsManager> reportManagerMap)
        {
            _reportProvider = reportProvider;
            _exportContentService = exportContentService;
            _bus = bus;
            _logger = logger;
            _reportManagerMap = reportManagerMap;
        }

        [HttpGet]
        [Route("provider")]
        [NoEnrichment]
        public async Task<ProviderInfo> GetReportProviderInfo()
        {
            return await _reportProvider.GetReportProviderInfo();
        }

        [HttpPost]
        [Route("billingworksheet")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.BillingWorksheet)]
        public async Task<int> GenerateBillingWorkSheet(JObject criteria)
        {
            return await ScheduleReport(ReportsTypes.BillingWorksheet, criteria);
        }

        async Task<int> ScheduleReport(string reportType, JObject criteria)
        {
            int contentId;
            try
            {
                if (criteria == null) throw new ArgumentNullException(nameof(criteria));

                contentId = await _exportContentService.GenerateContentId((string)criteria["connectionId"], (string)criteria["reportName"]);

                var request = await _reportManagerMap[reportType].CreateReportRequest(criteria, contentId);

                var args = new ReportGenerationRequiredMessage(request);

                await _bus.PublishAsync(args);
            }
            catch (Exception ex)
            {
                _logger.Exception(ex);
                contentId = -1;
            }

            return contentId;
        }
    }
}