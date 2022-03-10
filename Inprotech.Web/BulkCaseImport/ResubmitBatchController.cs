using System;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.BulkCaseImport.Validators;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.BulkCaseImport
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.BulkCaseImport)]
    [RoutePrefix("api/bulkcaseimport")]
    public class ResubmitBatchController : ApiController
    {
        readonly IBulkLoadProcessing _bulkLoadProcessing;
        readonly IDbContext _dbContext;

        public ResubmitBatchController(IDbContext dbContext, IBulkLoadProcessing bulkLoadProcessing)
        {
            if(dbContext == null) throw new ArgumentNullException("dbContext");
            if(bulkLoadProcessing == null) throw new ArgumentNullException("bulkLoadProcessing");

            _dbContext = dbContext;
            _bulkLoadProcessing = bulkLoadProcessing;
        }

        [HttpPost]
        [Route("resubmitbatch")]
        public dynamic ResubmitBatch(JObject batch)
        {
            if (batch == null || string.IsNullOrWhiteSpace(batch.Value<string>("batchId"))) 
                throw new ArgumentNullException("batch");
            
            var bId = int.Parse(batch.Value<string>("batchId"));

            ValidationError error;

            var senderRequest =
                _dbContext.Set<EdeSenderDetails>().Single(p => p.TransactionHeader.BatchId == bId);

            if(!ValidateEdeBatch(senderRequest, out error)) return CreateErrorResponse(error);
            if(!ValidateAndCleanProcessRequest(senderRequest, out error)) return CreateErrorResponse(error);

            _bulkLoadProcessing.SubmitToEde(bId);

            return new
                   {
                       result = "success"
                   };
        }

        bool ValidateAndCleanProcessRequest(EdeSenderDetails senderDetails, out ValidationError error)
        {
            error = null;
            var existingRequests =
                _dbContext.Set<ProcessRequest>().Where(p => p.BatchId == senderDetails.TransactionHeader.BatchId);

            if(existingRequests.Any(r => r.Status != null && r.Status.Id == (int)ProcessRequestStatus.Processing))
            {
                error =
                    new ValidationError(
                        String.Format(Resources.ErrorBatchInProgress, senderDetails.SenderRequestIdentifier));
                return false;
            }

            foreach(var e in existingRequests.ToList())
            {
                _dbContext.Set<ProcessRequest>().Remove(e);
            }

            _dbContext.SaveChanges();
            return true;
        }
        static bool ValidateEdeBatch(EdeSenderDetails senderDetails, out ValidationError error)
        {
            error = null;
            var transactionStatus = senderDetails.TransactionHeader.BatchStatus.Id;

            if (transactionStatus == EdeBatchStatus.Processed || transactionStatus == EdeBatchStatus.OutputProduced)
            {
                error =
                    new ValidationError(
                        String.Format(Resources.ErrorBatchAlreadyProcessed, senderDetails.SenderRequestIdentifier));
                return false;
            }
            return true;
        }

        static dynamic CreateErrorResponse(ValidationError error)
        {
            return new
                   {
                       result = "error",
                       error.ErrorMessage
                   };
        }
    }
}