using System;
using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.Extensions;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.BulkCaseImport)]
    [RoutePrefix("api/bulkcaseimport")]
    [ViewInitialiser]
    public class MappingIssuesViewController : ApiController
    {
        readonly IDbContext _dbContext;

        public MappingIssuesViewController(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("mappingissuesview")]
        public dynamic Get(int batchId)
        {
            var data = _dbContext.Set<EdeSenderDetails>()
                                       .ImportedFromFile()
                                       .Where(sd => sd.TransactionHeader.BatchId == batchId)
                                       .Include(sd => sd.TransactionHeader.TransactionBodies)
                                       .Select(esd => new
                                       {
                                           batchIdentifier = esd.SenderRequestIdentifier,
                                           notMappedCount = esd.TransactionHeader.TransactionBodies.Count(tb => tb.TransactionStatus.Id == (int)TransactionStatus.UnmappedCodes),
                                       }).First();

            var issuesData = _dbContext.Set<EdeOutstandingIssues>()
                                        .Include(o => o.StandardIssue)
                                        .Where( o => o.BatchId == batchId && o.TransactionIdentifier == null && o.StandardIssue.Id == Issues.UnmappedCode)
                                        .Select(o => new {o.StandardIssue, o.Issue})
                                        .Distinct()
                                        .ToArray();

            return new
            {
                batchId,
                data.batchIdentifier,
                mappingIssueCaseCount = data.notMappedCount,
                issueDescription = issuesData.Select(id => id.StandardIssue.LongDescription ?? id.StandardIssue.ShortDescription).First(),
                mappingIssues = issuesData.Select(id => id.Issue).ToArray()
            };
        }
    }
}
