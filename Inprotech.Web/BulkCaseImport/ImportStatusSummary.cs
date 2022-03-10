using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Legacy;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.Extensions;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport
{
    public enum BatchStatus
    {
        ResolutionRequired,
        InProgress,
        Error,
        Processed
    }

    public enum StatusType
    {
        Error,
        Unmapped,
        Outstanding,
        Total
    }

    public interface IImportStatusSummary
    {
        Task<(IEnumerable<object> Data, int Total)> Retrieve(CommonQueryParameters queryParameters);
        Task<IEnumerable<CodeDescription>> RetrieveFilterData(string field);
    }

    public class ImportStatusSummary : IImportStatusSummary
    {
        readonly Dictionary<string, string> _availabeFilterPropertyMapping = new Dictionary<string, string>
        {
            {"displayStatusType", nameof(ImportStatusSummaryViewModel.DisplayStatusType)}
        };

        readonly ICommonQueryService _commonQueryService;
        readonly IDbContext _dbContext;
        readonly ISiteConfiguration _siteConfiguration;

        readonly Dictionary<ProcessRequestStatus, BatchStatus> _statusMap = new Dictionary<ProcessRequestStatus, BatchStatus>
        {
            {ProcessRequestStatus.Processing, BatchStatus.InProgress},
            {ProcessRequestStatus.Error, BatchStatus.Error}
        };

        public ImportStatusSummary(IDbContext dbContext, ISiteConfiguration siteConfiguration, ICommonQueryService commonQueryService)
        {
            _dbContext = dbContext;
            _siteConfiguration = siteConfiguration;
            _commonQueryService = commonQueryService;
        }

        public async Task<IEnumerable<CodeDescription>> RetrieveFilterData(string field)
        {
            EdeSenderDetails[] batches = null;
            switch (field)
            {
                case "displayStatusType":
                    batches = await _dbContext.Set<EdeSenderDetails>()
                                              .ImportedFromFile()
                                              .Include(sd => sd.TransactionHeader)
                                              .ToArrayAsync();
                    break;
            }

            var result = new List<CodeDescription>();
            if (batches == null || !batches.Any()) return result;

            var uniqueBatchIds = batches.Select(sd => (int?) sd.TransactionHeader.BatchId).ToArray();
            var statuses = await _dbContext.Set<ProcessRequest>()
                                           .Where(pr => uniqueBatchIds.Contains(pr.BatchId)).ToArrayAsync();
            var issues = await _dbContext.Set<EdeOutstandingIssues>()
                                         .Include(o => o.StandardIssue)
                                         .Where(o => uniqueBatchIds.Contains(o.BatchId)
                                                     && o.TransactionIdentifier == null && o.StandardIssue.Id != Issues.UnmappedCode)
                                         .ToArrayAsync();

            foreach (var b in batches)
            {
                var resolvedStatus = ResolveBatchStatus(b.TransactionHeader.BatchStatus,
                                                        statuses.SingleOrDefault(s => s.BatchId == b.TransactionHeader.BatchId),
                                                        issues.Where(i => i.BatchId == b.TransactionHeader.BatchId).ToArray());

                result.Add(_commonQueryService.BuildCodeDescriptionObject(resolvedStatus.DisplayStatusType, resolvedStatus.DisplayStatusType));
            }

            return result.Distinct();
        }

        public async Task<(IEnumerable<object> Data, int Total)> Retrieve(CommonQueryParameters queryParameters)
        {
            if (queryParameters == null) throw new ArgumentNullException(nameof(queryParameters));

            var rejectedTransactionReturnCodes = TransactionReturnCode.Map[TransactionReturnCode.RejectedCases];
            var amendedTransactionReturnCodes = TransactionReturnCode.Map[TransactionReturnCode.AmendedCases];
            var noChangesTransactionReturnCodes = TransactionReturnCode.Map[TransactionReturnCode.NoChangeCases];
            var newCasesTransactionReturnCodes = TransactionReturnCode.Map[TransactionReturnCode.NewCases];

            var filter = queryParameters.Filters.SingleOrDefault();

            var batches = await _dbContext.Set<EdeSenderDetails>()
                                          .ImportedFromFile()
                                          .Include(sd => sd.TransactionHeader)
                                          .Include(sd => sd.TransactionHeader.TransactionBodies)
                                          .Include(sd => sd.TransactionHeader.BatchStatus)
                                          .OrderByDescending(sd => sd.LastModified)
                                          .Select(esd => new
                                          {
                                              SenderDetails = esd,
                                              esd.TransactionHeader.BatchId,
                                              SubmittedDate = esd.LastModified,
                                              esd.TransactionHeader.BatchStatus,
                                              BatchIdentifier = esd.SenderRequestIdentifier,
                                              Total = esd.TransactionHeader.TransactionBodies.Count(),
                                              NewCases = esd.TransactionHeader.TransactionBodies.Count(tb => newCasesTransactionReturnCodes.Contains(tb.TransactionReturnCode)),
                                              Amended = esd.TransactionHeader.TransactionBodies.Count(tb => amendedTransactionReturnCodes.Contains(tb.TransactionReturnCode) && tb.TransactionStatus.Id == (int) TransactionStatus.Processed),
                                              NoChange = esd.TransactionHeader.TransactionBodies.Count(tb => noChangesTransactionReturnCodes.Contains(tb.TransactionReturnCode) && tb.TransactionStatus.Id == (int) TransactionStatus.Processed),
                                              Rejected = esd.TransactionHeader.TransactionBodies.Count(tb => rejectedTransactionReturnCodes.Contains(tb.TransactionReturnCode)),
                                              NotMapped = esd.TransactionHeader.TransactionBodies.Count(tb => tb.TransactionStatus.Id == (int) TransactionStatus.UnmappedCodes),
                                              NameIssues = esd.TransactionHeader.TransactionBodies.Count(tb => tb.TransactionStatus.Id == (int) TransactionStatus.UnresolvedNames)
                                          }).ToArrayAsync();

            var uniqueBatchIds = batches.Select(sd => (int?) sd.BatchId).ToArray();

            var uniqueSenders = batches.Select(sd => sd.SenderDetails.Sender).Distinct();

            var statuses = _dbContext.Set<ProcessRequest>()
                                     .Where(pr => uniqueBatchIds.Contains(pr.BatchId)).ToArray();

            var issues = _dbContext.Set<EdeOutstandingIssues>()
                                   .Include(o => o.StandardIssue)
                                   .Where(o => uniqueBatchIds.Contains(o.BatchId) && o.TransactionIdentifier == null && o.StandardIssue.Id != Issues.UnmappedCode).ToArray();

            var homeName = _siteConfiguration.HomeName().Id;

            var senderMap = CreateSenderMap(uniqueSenders);

            var result = new List<ImportStatusSummaryViewModel>();

            foreach (var c in batches)
            {
                var current = c;
                var formattedName = string.Empty;
                var isHomeName = false;

                var url = string.Empty;
                Name name;
                if (senderMap.TryGetValue(c.SenderDetails.Sender, out name))
                {
                    formattedName = name.Formatted();
                    isHomeName = name.Id == homeName;

                    if (c.NewCases > 0)
                    {
                        url = BuildUrl(c.BatchIdentifier, name.Id);
                    }
                }

                var batch = ResolveBatchStatus(c.BatchStatus,
                                               statuses.SingleOrDefault(s => s.BatchId == current.BatchId),
                                               issues.Where(i => i.BatchId == current.BatchId).ToArray());

                result.Add(new ImportStatusSummaryViewModel
                {
                    Id = c.BatchId,
                    SubmittedDate = c.SubmittedDate,
                    StatusType = batch.StatusType.ToString(),
                    StatusMessage = batch.StatusMessage,
                    DisplayStatusType = string.IsNullOrWhiteSpace(batch.StatusMessage) ? batch.StatusType.ToString() : batch.StatusMessage,
                    IsHomeName = isHomeName,
                    Source = formattedName,
                    BatchIdentifier = c.BatchIdentifier,
                    NewCasesUrl = url,
                    Rejected = ValueOrNull(c.Rejected),
                    NewCases = ValueOrNull(c.NewCases),
                    Total = ValueOrNull(c.Total),
                    NotMapped = ValueOrNull(c.NotMapped),
                    NameIssues = ValueOrNull(c.NameIssues),
                    Amended = ValueOrNull(c.Amended),
                    NoChange = ValueOrNull(c.NoChange),
                    Unresolved = ValueOrNull(c.Total - c.NotMapped - c.NameIssues - c.NewCases - c.Rejected - c.Amended - c.NoChange),
                    OtherErrors = batch.OtherErrors,
                    IsReversible = batch.IsReversible
                });
            }

            if (filter != null && _availabeFilterPropertyMapping.TryGetValue(filter.Field, out var mappedField))
            {
                filter.Field = mappedField;
            }

            var resultFiltered = result.FilterByProperty(filter?.Field, filter?.Operator, filter?.Value);

            var importStatusSummaryViewModels = resultFiltered as ImportStatusSummaryViewModel[] ?? resultFiltered.ToArray();
            return (importStatusSummaryViewModels.Skip(queryParameters.Skip ?? 0).Take(queryParameters.Take ?? int.MaxValue), importStatusSummaryViewModels.Length);
        }

        Dictionary<string, Name> CreateSenderMap(IEnumerable<string> uniqueSenders)
        {
            return _dbContext.Set<NameAlias>()
                             .Include(na => na.Name)
                             .Where(na =>
                                        na.AliasType.Code == KnownAliasTypes.EdeIdentifier &&
                                        uniqueSenders.Contains(na.Alias))
                             .Select(_ => new
                             {
                                 _.Alias,
                                 _.Name
                             })
                             .ToArray()
                             .ToDictionary(k => k.Alias, v => v.Name);
        }

        static string BuildUrl(string batchIdentifier, int dataSourceKey)
        {
            return string.Format(KnownUrls.EdeBatch, dataSourceKey, HttpUtility.HtmlEncode(batchIdentifier));
        }

        ResolvedBatchStatus ResolveBatchStatus(TableCode batchTransactionStatus, ProcessRequest processRequest, EdeOutstandingIssues[] otherIssues)
        {
            var status = BatchStatus.Processed;
            var statusMessage = string.Empty;
            var errorFromProcess = string.Empty;

            if (processRequest?.Status != null)
            {
                if (_statusMap.TryGetValue((ProcessRequestStatus) processRequest.Status.Id, out status) && status == BatchStatus.Error)
                {
                    errorFromProcess = processRequest.StatusMessage;
                }
            }

            if (status == BatchStatus.Processed && batchTransactionStatus != null)
            {
                if (batchTransactionStatus.Id == EdeBatchStatus.Unprocessed)
                {
                    status = BatchStatus.ResolutionRequired;
                }

                statusMessage = batchTransactionStatus.Name;
            }

            if (otherIssues.Any() || !string.IsNullOrWhiteSpace(errorFromProcess))
            {
                status = BatchStatus.Error;
                statusMessage = string.Empty;
            }

            var isErrorProcessOrNotInProgress = processRequest == null || !string.IsNullOrWhiteSpace(errorFromProcess);

            return new ResolvedBatchStatus
            {
                IsReversible = isErrorProcessOrNotInProgress && batchTransactionStatus?.Id != EdeBatchStatus.OutputProduced,
                StatusType = status,
                StatusMessage = statusMessage,
                DisplayStatusType = string.IsNullOrWhiteSpace(statusMessage) ? status.ToString() : statusMessage,
                OtherErrors = ErrorDetails(errorFromProcess, otherIssues)
            };
        }

        static dynamic ErrorDetails(string errorFromProcess, EdeOutstandingIssues[] otherIssues)
        {
            if (string.IsNullOrWhiteSpace(errorFromProcess) && !otherIssues.Any())
            {
                return null;
            }

            var errors = new List<string>();
            if (!string.IsNullOrWhiteSpace(errorFromProcess))
            {
                errors.Add(errorFromProcess);
            }

            return new
            {
                TitleResId = "bulkCaseImport.isErrorDetailsTitle",
                Issues = errors.Concat(otherIssues.Select(i => i.IssueDescription()).ToArray()).ToArray()
            };
        }

        static int? ValueOrNull(int v)
        {
            return v == 0 ? (int?) null : v;
        }

        public class ResolvedBatchStatus
        {
            public bool IsReversible { get; set; }
            public BatchStatus StatusType { get; set; }
            public string StatusMessage { get; set; }
            public string DisplayStatusType { get; set; }
            public dynamic OtherErrors { get; set; }
        }
    }

    public class ImportStatusSummaryViewModel
    {
        public int Id { get; set; }
        public DateTime? SubmittedDate { get; set; }
        public string StatusType { get; set; }
        public string StatusMessage { get; set; }
        public string DisplayStatusType { get; set; }
        public bool IsHomeName { get; set; }
        public string Source { get; set; }
        public string BatchIdentifier { get; set; }
        public string NewCasesUrl { get; set; }
        public int? Rejected { get; set; }
        public int? NewCases { get; set; }
        public int? Total { get; set; }
        public int? NotMapped { get; set; }
        public int? NameIssues { get; set; }
        public int? Amended { get; set; }
        public int? NoChange { get; set; }
        public int? Unresolved { get; set; }
        public dynamic OtherErrors { get; set; }
        public bool IsReversible { get; set; }
    }
}