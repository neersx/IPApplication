using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Search.Export;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using InprotechKaizen.Model.Components.Integration.Jobs;
using Activity = Dependable.Activity;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public interface IPatentsDownload
    {
        Task<Activity> Process(long storageId);
    }

    public class PatentsDownload : IPatentsDownload
    {
        readonly IInnographyPatentsDataMatchingClient _innographyDataMatchingClient;
        readonly IInnographyPatentsDataValidationClient _innographyDataValidationClient;
        readonly IInnographyPatentsValidationRequestMapping _innographyValidationRequestMapping;
        readonly IEligiblePatentItems _eligiblePatentItems;
        readonly IBackgroundProcessLogger<PatentsDownload> _logger;
        readonly IJobArgsStorage _jobArgsStorage;

        public PatentsDownload(IInnographyPatentsDataMatchingClient innographyDataMatchingClient,
                                IInnographyPatentsDataValidationClient innographyDataValidationClient,
                                IInnographyPatentsValidationRequestMapping innographyValidationRequestMapping,
                                IEligiblePatentItems eligiblePatentItems,
                                IJobArgsStorage jobArgsStorage,
                                IBackgroundProcessLogger<PatentsDownload> logger)
        {
            _innographyDataMatchingClient = innographyDataMatchingClient;
            _innographyDataValidationClient = innographyDataValidationClient;
            _innographyValidationRequestMapping = innographyValidationRequestMapping;
            _eligiblePatentItems = eligiblePatentItems;
            _jobArgsStorage = jobArgsStorage;
            _logger = logger;
        }

        public async Task<Activity> Process(long storageId)
        {
            var cases = await _jobArgsStorage.GetAsync<DataDownload[]>(storageId);

            var caseIds = cases.Select(_ => _.Case.CaseKey).ToArray();

            var message = new StringBuilder();

            message.AppendLine($"Processing {caseIds.Length} patents from storage ({storageId})");

            var timeTaken = new Stopwatch();
            var section = new Stopwatch();

            timeTaken.Start();
            section.Start();

            var patentsRequest = _eligiblePatentItems.Retrieve(caseIds).Select(c => new PatentDataMatchingRequest
                                         {
                                             ClientIndex = c.CaseKey.ToString(),
                                             ApplicationNumber = c.ApplicationNumber,
                                             ApplicationDate = c.ApplicationDate.DateOrNull(),
                                             PublicationNumber = c.PublicationNumber,
                                             PublicationDate = c.PublicationDate.DateOrNull(),
                                             GrantNumber = c.RegistrationNumber,
                                             GrantDate = c.RegistrationDate.DateOrNull(),
                                             GrantPublicationDate = c.GrantPublicationDate.DateOrNull(),
                                             CountryCode = c.CountryCode,
                                             TypeCode = c.TypeCode,
                                             PctDate = c.PctDate.DateOrNull(),
                                             PctNumber = c.PctNumber,
                                             PctCountry = c.PctCountry,
                                             ParentDate = c.PriorityDate.DateOrNull(),
                                             ParentNumber = c.PriorityNumber,
                                             ParentCountry = c.PriorityCountry
                                         }).ToList();

            message.AppendLine($"{section.Elapsed} to build request from data.");
            section.Restart();

            var response = await _innographyDataMatchingClient.IpIdApi(new InnographyIdApiRequest(patentsRequest));

            var idResponse = response.Result.ToDictionary(k => int.Parse(k.ClientIndex), v => v);

            var dvRequests = _innographyValidationRequestMapping.MapRequests(response.Result, patentsRequest);
            
            var workflow = new List<Activity>();

            var innographyDataResults = await _innographyDataValidationClient.ValidationApi(dvRequests);

            message.AppendLine($"{section.Elapsed} to receive request from Innography.");
            section.Stop();

            var anyMatches = (from r in innographyDataResults.Result
                              join c in cases on new { CaseKey = r.ClientIndex } equals new { CaseKey = c.Case.CaseKey.ToString() } into c1
                              from c in c1
                              select c.WithExtendedDetails(r)).ToArray();

            var nonMatches = cases.Except(anyMatches).ToArray();

            var all = anyMatches.Concat(nonMatches).ToArray();

            var itemsToDiscard = all
                                 .Where(_ =>
                                 {
                                     var r = idResponse[_.Case.CaseKey];
                                     return r.HasInvalidInnographyId() || r.Matched("low");
                                 })
                                 .ToArray();

            var itemsToDiscardIds = itemsToDiscard.Select(_ => _.Case.CaseKey).ToArray();

            var sessionGuid = cases.First().Id;

            if (itemsToDiscard.Any())
            {
                workflow.Add(Activity.Run<DetailsUnavailable>(_ => _.DiscardNofitications(sessionGuid, itemsToDiscardIds))
                                     .ThenContinue());
            }

            var keep = all.Except(itemsToDiscard)
                          .Select(c =>
                          {
                              var isMatch = idResponse[c.Case.CaseKey].IsHighConfidenceMatch();
                              return Activity.Run<IDownloadedCase>(_ => _.Process(c, isMatch))
                                             .ExceptionFilter<ErrorLogger>((ex, e) => e.Log(ex, c))
                                             .Failed(Activity.Run<IDownloadFailedNotification>(d => d.Notify(c)))
                                             .ThenContinue();
                          })
                          .ToArray();

            if (keep.Any()) workflow.AddRange(keep);

            timeTaken.Stop();

            if (timeTaken.Elapsed.TotalSeconds > 10)
            {
                message.AppendLine($"Initial={cases.Length}");
                message.AppendLine($"Sent={all.Length}");
                message.AppendLine($"Matched={keep.Length}");
                message.AppendLine($"Discard={itemsToDiscard.Length}");

                _logger.Warning($"This Innography schedule for Patents ({sessionGuid}) took {timeTaken.Elapsed}", message.ToString());
            }

            return Activity.Sequence(workflow);
        }
    }
}
