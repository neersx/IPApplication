using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Policing
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.ViewPolicingDashboard)]
    [RequiresAccessTo(ApplicationTask.PolicingAdministration)]
    [RoutePrefix("api/policing/queue")]
    public class PolicingQueueController : ApiController
    {
        readonly ICommonQueryService _commonQueryService;
        readonly IErrorReader _errorReader;
        readonly IPolicingQueue _policingQueue;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IDashboardDataProvider _dashboardDataProvider;

        public PolicingQueueController(IPolicingQueue policingQueue,
                                       ICommonQueryService commonQueryService,
                                       IErrorReader errorReader,
                                       ITaskSecurityProvider taskSecurityProvider,
                                       IDashboardDataProvider dashboardDataProvider)
        {
            if (policingQueue == null) throw new ArgumentNullException("policingQueue");
            if (commonQueryService == null) throw new ArgumentNullException("commonQueryService");
            if (errorReader == null) throw new ArgumentNullException("errorReader");
            if (taskSecurityProvider == null) throw new ArgumentNullException("taskSecurityProvider");
            if (dashboardDataProvider == null) throw new ArgumentNullException("dashboardDataProvider");

            _policingQueue = policingQueue;
            _commonQueryService = commonQueryService;
            _errorReader = errorReader;
            _taskSecurityProvider = taskSecurityProvider;
            _dashboardDataProvider = dashboardDataProvider;
        }

        [HttpGet]
        [Route("view")]
        public dynamic GetViewData()
        {
            return new
                   {
                       CanAdminister = _taskSecurityProvider.HasAccessTo(ApplicationTask.PolicingAdministration),
                       CanMaintainWorkflow = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules),
                       SummaryData = _dashboardDataProvider.Retrieve(RetrieveOption.Default).SummaryOnly()
                   };
        }

        [HttpGet]
        [Route("filterData/{field}/{queueType}")]
        public IEnumerable<CodeDescription> GetFilterDataForColumn(string field, string queueType,
                                                                   [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "columnFilters")] IEnumerable<CommonQueryParameters.FilterValue> columnFilters = null)
        {
            var qp = PolicingQueueQueryParameters.Get(new CommonQueryParameters
                                                      {
                                                          Filters = columnFilters
                                                      });

            return _policingQueue.AllowableFilters(queueType, field, qp);
        }

        [HttpGet]
        [Route("{byStatus}")]
        public dynamic Get(
            string byStatus,
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            return new
                   {
                       Items = GetItems(byStatus, PolicingQueueQueryParameters.Get(queryParameters)),
                       Summary = _dashboardDataProvider.Retrieve(RetrieveOption.Default).SummaryOnly()
                   };
        }

        [HttpGet]
        [Route("errors/{caseId}")]
        public PagedResults GetErrorsFor(
            int caseId,
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            return _errorReader.For(caseId)
                               .AsPagedResults(PolicingQueueQueryParameters.Get(queryParameters));
        }

        PagedResults GetItems(string byStatus, CommonQueryParameters qp)
        {
            var r = _commonQueryService.Filter(_policingQueue.Retrieve(byStatus), qp).AsPagedResults(qp);

            var queueItems = r.Items<PolicingQueueItem>().ToArray();

            var caseIds = (from q in queueItems where q.CaseId != null select (int) q.CaseId)
                .Distinct()
                .ToArray();

            var errors = _errorReader.Read(caseIds, 5);

            foreach (var q in queueItems)
                q.Error = errors.For(q.CaseId);

            return new PagedResults(queueItems, r.Pagination.Total);
        }
    }
}