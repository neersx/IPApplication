using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.BulkCaseImport)]
    [RoutePrefix("api/bulkcaseimport")]
    [NoEnrichment]
    public class ImportStatusController : ApiController
    {
        readonly IImportServer _importServer;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IDbArtifacts _dbArtifacts;
        readonly IImportStatusSummary _importStatusSummary;

        public ImportStatusController(IImportStatusSummary importStatusSummary, IImportServer importServer, 
                                      ITaskSecurityProvider taskSecurityProvider,
                                      IDbArtifacts dbArtifacts)
        {
            _importStatusSummary = importStatusSummary;
            _importServer = importServer;
            _taskSecurityProvider = taskSecurityProvider;
            _dbArtifacts = dbArtifacts;
        }

        [HttpGet]
        [Route("importstatus")]
        public async Task<PagedResults> Get(HttpRequestMessage request, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                            CommonQueryParameters queryParameters)
        {
            if (queryParameters == null)
            {
                queryParameters = new CommonQueryParameters {Skip = 0, Take = 50};
            }

            _importServer.TryResetAbortedProcesses();

            var result = await _importStatusSummary.Retrieve(queryParameters);

            return new PagedResults(result.Data, result.Total);
        }

        [HttpGet]
        [Route("importstatus/filterData/{field}")]
        public async Task<IEnumerable<CodeDescription>> GetFilterDataForColumn(string field = "")
        {
            return await _importStatusSummary.RetrieveFilterData(field);
        }

        [HttpGet]
        [Route("permissions")]
        public dynamic Permissions()
        {
            var hasReversibleInformation = _dbArtifacts.Exists(InprotechKaizen.Model.AuditTrail.Logging.Cases, SysObjects.Table, SysObjects.View);

            return new
            {
                CanReverseBatch = hasReversibleInformation && _taskSecurityProvider.HasAccessTo(ApplicationTask.ReverseImportedCases)
            };
        }
    }
}