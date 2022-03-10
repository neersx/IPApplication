using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Processing;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.BulkCaseImport.Validators;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.BulkCaseImport
{
    [Authorize]
    [RoutePrefix("api/bulkcaseimport")]
    [RequiresAccessTo(ApplicationTask.ReverseImportedCases)]
    public class ReverseImportedCasesController : ApiController
    {
        readonly IAsyncCommandScheduler _asyncCommandScheduler;
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public ReverseImportedCasesController(IDbContext dbContext, ISecurityContext securityContext, IAsyncCommandScheduler asyncCommandScheduler)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _asyncCommandScheduler = asyncCommandScheduler;
        }

        [HttpPost]
        [Route("reversebatch")]
        public async Task<dynamic> Reverse(JObject batch)
        {
            if (batch == null || string.IsNullOrWhiteSpace(batch.Value<string>("batchId")))
            {
                throw new ArgumentNullException(nameof(batch));
            }

            var batchId = batch.Value<int>("batchId");

            var edeProcessRequest = from pr in _dbContext.Set<ProcessRequest>()
                                    where pr.Context == ProcessRequestContexts.ElectronicDataExchange && pr.RequestType == "EDE Resubmit Batch"
                                    select pr;

            var r = await (from eth in _dbContext.Set<EdeTransactionHeader>()
                           join pr in edeProcessRequest on new {BatchId = (int?) eth.BatchId} equals new {pr.BatchId} into pr1
                           from pr in pr1.DefaultIfEmpty()
                           where eth.BatchId == batchId
                           select new
                           {
                               eth.BatchId,
                               BatchStatus = eth.BatchStatus != null ? eth.BatchStatus.Id : (int?) null,
                               pr
                           }).SingleOrDefaultAsync();

            if (r == null) return CreateErrorResponse(new ValidationError("batch-not-found"));

            if (r.BatchStatus == EdeBatchStatus.OutputProduced) return CreateErrorResponse(new ValidationError("batch-output-produced"));

            var isErrorBatch = r.pr?.Status?.Id == (int)ProcessRequestStatus.Error;
            
            if (isErrorBatch)
            {
                _dbContext.Set<ProcessRequest>().Remove(r.pr);

                await _dbContext.SaveChangesAsync();
            }
            else if (r.pr != null)
            {
                return CreateErrorResponse(new ValidationError("batch-already-being-reversed"));
            }
            
            await _asyncCommandScheduler.ScheduleAsync("apps_ReverseCaseImportBatch",
                                                       new Dictionary<string, object>
                                                       {
                                                           {"@pnUserIdentityId", _securityContext.User.Id},
                                                           {"@pnBatchNo", batchId}
                                                       });

            return new
            {
                Result = "success"
            };
        }

        static dynamic CreateErrorResponse(ValidationError error)
        {
            return new
            {
                Result = "error",
                ErrorCode = error.ErrorMessage
            };
        }
    }
}