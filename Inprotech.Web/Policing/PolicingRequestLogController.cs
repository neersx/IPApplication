using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Policing.Forecast;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Reminders;

namespace Inprotech.Web.Policing
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.ViewPolicingDashboard)]
    [RequiresAccessTo(ApplicationTask.PolicingAdministration)]
    [RoutePrefix("api/policing/requestlog")]
    public class PolicingRequestLogController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ICommonQueryService _commonQueryService;
        readonly IPolicingRequestLogReader _policingRequestLogReader;
        readonly IRequestLogErrorReader _requestLogErrorReader;
        readonly IPolicingRequestSps _policingRequestSps;
        readonly ITaskSecurityProvider _securityProvider;
        readonly IInprotechVersionChecker _inprotechVersionChecker;

        public PolicingRequestLogController(IPolicingRequestLogReader policingRequestLogReader,
                                            ITaskSecurityProvider securityProvider,
                                            ICommonQueryService commonQueryService,
                                            IRequestLogErrorReader requestLogErrorReader,
                                            IPolicingRequestSps policingRequestSps, 
                                            IInprotechVersionChecker inprotechVersionChecker, IDbContext dbContext)
        {
            _policingRequestLogReader = policingRequestLogReader;
            _requestLogErrorReader = requestLogErrorReader;
            _policingRequestSps = policingRequestSps;
            _inprotechVersionChecker = inprotechVersionChecker;
            _dbContext = dbContext;
            _securityProvider = securityProvider;
            _commonQueryService = commonQueryService;
        }

        [HttpGet]
        [Route("view")]
        public dynamic View()
        {
            return new
                   {
                       CanViewOrMaintainRequests = _securityProvider.HasAccessTo(ApplicationTask.MaintainPolicingRequest),
                       CanMaintainWorkflow = _securityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules)
                   };
        }

        [HttpGet]
        [Route("recent")]
        public dynamic Recent()
        {
            var canCalculateAffectedCases = _policingRequestSps.GetNoOfAffectedCases(0, true);
            return new
                   {
                       CanViewOrMaintainRequests = _securityProvider.HasAccessTo(ApplicationTask.MaintainPolicingRequest),
                       Requests = _policingRequestLogReader.Retrieve().Take(10),
                       CanCalculateAffectedCases = canCalculateAffectedCases?.IsSupported ?? false
                   };
        }

        [HttpGet]
        [Route("")]
        public dynamic Get([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            var isMinimumVersion16 = _inprotechVersionChecker.CheckMinimumVersion(16);
            var canDeleteRequestLog = _securityProvider.HasAccessTo(ApplicationTask.PolicingAdministration);
            var result = _commonQueryService.Filter(_policingRequestLogReader.Retrieve(), queryParameters)
                                            .AsPagedResults(queryParameters);
            var requestLogItems = result.Items<PolicingRequestLogItem>().ToArray();
            if (isMinimumVersion16 && canDeleteRequestLog)
            {
                var sysActiveSession = _dbContext.GetSysActiveSessions();
                foreach (var request in requestLogItems)
                {
                    if (request.SpId != null && request.FinishDateTime == null && string.IsNullOrEmpty(request.FailMessage))
                    {
                        request.CanDelete = sysActiveSession.Count(_ => _.Session_Id == request.SpId && _.Last_Request_Start_Time == request.SpIdStart) == 0;
                    }
                }
            }
            var startDateTimes = (from r in requestLogItems select r.StartDateTime)
                                 .Distinct()
                                 .ToArray();

            var errors = _requestLogErrorReader.Read(startDateTimes, 5);

            foreach (var r in requestLogItems)
                r.Error = errors.For(r.StartDateTime);

            return new PagedResults(requestLogItems, result.Pagination.Total);
        }

        [HttpGet]
        [Route("errors/{policingLogId}")]
        public dynamic GetErrors(int policingLogId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            return _commonQueryService.Filter(_requestLogErrorReader.For(policingLogId), queryParameters)
                                      .AsPagedResults(queryParameters);
        }

        [HttpGet]
        [Route("filterData/{field}")]
        public IEnumerable<CodeDescription> GetFilterDataForColumn(string field,
                                                                   [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "columnFilters")] IEnumerable<CommonQueryParameters.FilterValue> columnFilters)
        {
            return _policingRequestLogReader.AllowableFilters(field, new CommonQueryParameters
                                                                     {
                                                                         Filters = columnFilters
                                                                     });
        }

        [HttpGet]
        [Route("delete/{policingLogId}")]
        public dynamic DeletePolicingLog(int policingLogId)
        {
            var result = false;
            var canDeleteRequestLog = _securityProvider.HasAccessTo(ApplicationTask.PolicingAdministration);

            var deletingItem = _dbContext.Set<PolicingLog>().SingleOrDefault(v => v.PolicingLogId == policingLogId && v.SpId != null && v.FinishDateTime == null && string.IsNullOrEmpty(v.FailMessage));
            if (deletingItem != null && canDeleteRequestLog)
            {
                _dbContext.Set<PolicingLog>().Remove(deletingItem);
                _dbContext.SaveChanges();
                result = true;
            }

            return new
            {
                Result = new
                {
                    Status = result ? "success" : "error"
                }
            };
        }
    }
}