using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;

namespace Inprotech.Web.Policing
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.ViewPolicingDashboard)]
    [RequiresAccessTo(ApplicationTask.PolicingAdministration)]
    [RoutePrefix("api/policing/errorLog")]
    public class PolicingErrorLogController : ApiController
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IPolicingErrorLog _errorLog;
        readonly IDbContext _dbContext;

        public PolicingErrorLogController(ITaskSecurityProvider taskSecurityProvider, IPolicingErrorLog errorLog, IDbContext dbContext)
        {
            _taskSecurityProvider = taskSecurityProvider;
            _errorLog = errorLog;
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("view")]
        public dynamic View()
        {
            return new
                   {
                       Permissions = new
                                     {
                                         CanAdminister = _taskSecurityProvider.HasAccessTo(ApplicationTask.PolicingAdministration),
                                         CanMaintainWorkflow = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules)
                                     }
                   };
        }

        [HttpGet]
        [Route("")]
        public PagedResults Errors(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            var p = queryParameters ?? new CommonQueryParameters();
            var pagedResult = _errorLog.Retrieve(p).AsPagedResults(p);

            var result = _errorLog.SetInProgressFlag(pagedResult.Data);

            return new PagedResults(result, pagedResult.Pagination.Total);
        }
        
        [HttpPost]
        [Route("delete")]
        public async Task<dynamic> Delete(int[] errorIds)
        {
            var errors = _dbContext.Set<PolicingError>();

            await _dbContext.DeleteAsync(errors.Where(_ => errorIds.Contains(_.PolicingErrorsId)));

            return new
            {
                Status = "success"
            };
        }
    }
}