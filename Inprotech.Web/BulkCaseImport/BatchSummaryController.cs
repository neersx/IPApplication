using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.Extensions;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.BulkCaseImport)]
    [RoutePrefix("api/bulkcaseimport")]
    [NoEnrichment]
    public class BatchSummaryViewController : ApiController
    {
        static readonly Dictionary<string, string> MappedFilterFieldName = new Dictionary<string, string>
        {
            {nameof(BatchTransactionViewModel.Status).ToLowerInvariant(), $"{nameof(EdeTransactionBody.TransactionStatus)}.{nameof(TableCode.Id)}"}
        };

        readonly ICommonQueryService _commonQueryService;
        readonly IDbContext _dbContext;

        public BatchSummaryViewController(IDbContext dbContext, ICommonQueryService commonQueryService)
        {
            _dbContext = dbContext;

            _commonQueryService = commonQueryService;
        }

        [HttpGet]
        [Route("batchsummary/filterData/{field}")]
        public IEnumerable<CodeDescription> GetFilterDataForColumn(string field, int batchId, string transReturnCode = "")
        {
            IEnumerable<EdeTransactionBody> filteredTransactionCount = null;
            switch (field)
            {
                case "status":
                    filteredTransactionCount = _dbContext.Set<EdeTransactionBody>().Where(t => t.BatchId == batchId)
                                                         .Include(t => t.TransactionStatus)
                                                         .WithReturnCode(transReturnCode);
                    break;
            }

            return filteredTransactionCount?.OrderByDescending(x => x.TransactionStatus.Name ?? "Z").ToArray()
                                           .Select(ts => ts.TransactionStatus == null
                                                       ? new CodeDescription()
                                                       : _commonQueryService.BuildCodeDescriptionObject(ts.TransactionStatus?.Id.ToString(), ts.TransactionStatus?.Name))
                                           .Distinct();
        }

        [HttpGet]
        [Route("batchsummary/batchidentifier")]
        public dynamic GetBatchIdentifier(int batchId, string transReturnCode = "")
        {
            var batch = _dbContext.Set<EdeSenderDetails>()
                                  .SingleOrDefault(s => s.TransactionHeader.BatchId == batchId);

            if (batch == null)
            {
                return new HttpResponseMessage(HttpStatusCode.NotFound);
            }

            return new
            {
                Id = batchId,
                Name = batch.SenderRequestIdentifier,
                TransReturnCode = transReturnCode
            };
        }

        [HttpGet]
        [Route("batchsummary")]
        public PagedResults Get(int batchId, string transReturnCode = "", [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                CommonQueryParameters qp = null)
        {
            var filters = qp?.Filters.SingleOrDefault();
            if (filters != null && MappedFilterFieldName.TryGetValue(filters.Field, out var mappedFieldName))
            {
                filters.Field = mappedFieldName;
            }

            var filteredTransactionsQuerable = _dbContext.Set<EdeTransactionBody>().Where(t => t.BatchId == batchId)
                                                         .Include(t => t.TransactionStatus)
                                                         .Include(t => t.OutstandingIssues)
                                                         .Include(t => t.DescriptionDetails)
                                                         .Include(t => t.CaseDetails)
                                                         .Include(t => t.CaseMatch)
                                                         .Include(t => t.IdentifierNumberDetails)
                                                         .Include(t => t.IdentifierNumberDetails.Select(s => s.NumberType))
                                                         .Include(t => t.OutstandingIssues.Select(t1 => t1.StandardIssue))
                                                         .WithReturnCode(transReturnCode)
                                                         .FilterByProperty(filters?.Field, filters?.Operator, filters?.Value);

            var filteredTransactionCount = filteredTransactionsQuerable.Count();
            var filteredTransactions = filteredTransactionsQuerable.OrderBy(t => t.TransactionIdentifier).Skip(qp?.Skip ?? 0).Take(qp?.Take ?? int.MaxValue).ToArray();

            var result = PrepareReturnData(filteredTransactions);

            return new PagedResults(result, filteredTransactionCount);
        }

        IEnumerable<BatchTransactionViewModel> PrepareReturnData(IEnumerable<EdeTransactionBody> data)
        {
            var edeTransactionBodies = data as EdeTransactionBody[] ?? data.ToArray();
            var liveCaseIds = edeTransactionBodies.Select(s => s.CaseDetails != null
                                                              ? s.CaseDetails.CaseId
                                                              : s.CaseMatch?.LiveCaseId).ToArray();

            var matchLevelDescriptions = (from tb in edeTransactionBodies
                                          where tb.CaseMatch != null && tb.CaseMatch.MatchLevel != null
                                          select tb.CaseMatch.MatchLevel)
                .Distinct();
            
            var matchLevels = (from tc in _dbContext.Set<TableCode>()
                               where matchLevelDescriptions.Contains(tc.Id)
                               select new
                               {
                                   MatchLevel = tc.Id,
                                   Description = tc.Name
                               })
                .ToDictionary(k => k.MatchLevel, v => v.Description);

            var inproCases = _dbContext.Set<Case>()
                                       .Where(c => liveCaseIds.Contains(c.Id)).ToArray();

            foreach (var d in edeTransactionBodies)
            {
                var body = d;

                var inproCase = inproCases.SingleOrDefault(c => c.Id == (body.CaseDetails != null
                                                                    ? body.CaseDetails.CaseId
                                                                    : body.CaseMatch?.LiveCaseId));

                var officialNumber = body.IdentifierNumberDetails.Any(i => i.NumberType != null)
                    ? body.IdentifierNumberDetails.Where(
                                                         i => i.NumberType != null && i.AssociatedCaseRelationshipCode == null)
                          .OrderBy(i => i.NumberType.DisplayPriority).FirstOrDefault()
                    : body.IdentifierNumberDetails.FirstOrDefault(i => i.AssociatedCaseRelationshipCode == null);

                var shortTitle = body.DescriptionDetails.SingleOrDefault(_ => _.DescriptionCode == Constants.ShortTitleType);

                yield return new BatchTransactionViewModel
                {
                    Id = body.TransactionIdentifier,
                    Status = body.TransactionStatus?.Name,
                    Result = body.CaseMatch?.MatchLevel == null
                        ? body.TransactionReturnCode
                        : matchLevels[body.CaseMatch.MatchLevel.Value],
                    CaseReference = inproCase?.Irn,
                    Issues = ExtractIssues(body.OutstandingIssues),
                    PropertyType = body.CaseDetails?.CasePropertyTypeCode,
                    Country = body.CaseDetails?.CaseCountryCode,
                    OfficialNumber = officialNumber?.IdentifierNumberText,
                    CaseTitle = shortTitle?.DescriptionText
                };
            }
        }

        static IEnumerable<string> ExtractIssues(IEnumerable<EdeOutstandingIssues> issues)
        {
            return issues.Select(i => string.IsNullOrWhiteSpace(i.StandardIssue.LongDescription)
                                     ? i.StandardIssue.ShortDescription
                                     : i.StandardIssue.LongDescription).ToArray();
        }

        public class BatchTransactionViewModel
        {
            public string Id { get; set; }
            public string Status { get; set; }
            public string Result { get; set; }
            public string CaseReference { get; set; }
            public IEnumerable<string> Issues { get; set; }
            public string PropertyType { get; set; }
            public string Country { get; set; }
            public string OfficialNumber { get; set; }
            public string CaseTitle { get; set; }
        }
    }
}