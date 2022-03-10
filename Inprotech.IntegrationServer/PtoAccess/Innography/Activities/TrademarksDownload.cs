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
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using InprotechKaizen.Model.Components.Integration.Jobs;
using Activity = Dependable.Activity;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public interface ITrademarksDownload
    {
        Task<Activity> Process(long storageId);
    }

    public class TrademarksDownload : ITrademarksDownload
    {
        readonly IInnographyTradeMarksDataMatchingClient _matchingClient;
        readonly IInnographyTradeMarksDataValidationClient _dvClient;
        readonly IEligibleTrademarkItems _eligibleTrademarkItems;
        readonly IInnographyTrademarksValidationRequestMapping _requestMapping;
        readonly IBackgroundProcessLogger<TrademarksDownload> _logger;
        readonly IJobArgsStorage _jobArgsStorage;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;

        public TrademarksDownload(IInnographyTradeMarksDataMatchingClient matchingClient,
                                    IInnographyTradeMarksDataValidationClient dvClient,
                                    IInnographyTrademarksValidationRequestMapping requestMapping,
                                    IEligibleTrademarkItems eligibleTrademarkItems,
                                    IJobArgsStorage jobArgsStorage,
                                    IBackgroundProcessLogger<TrademarksDownload> logger,
                                    IDataDownloadLocationResolver dataDownloadLocationResolver)
        {
            _matchingClient = matchingClient;
            _dvClient = dvClient;
            _eligibleTrademarkItems = eligibleTrademarkItems;
            _requestMapping = requestMapping;
            _jobArgsStorage = jobArgsStorage;
            _logger = logger;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
        }

        public async Task<Activity> Process(long storageId)
        {
            var cases = await _jobArgsStorage.GetAsync<DataDownload[]>(storageId);

            var caseIds = cases.Select(_ => _.Case.CaseKey).ToArray();

            var message = new StringBuilder();

            message.AppendLine($"Processing {caseIds.Length} trademarks from storage ({storageId})");

            var timeTaken = new Stopwatch();
            var section = new Stopwatch();

            timeTaken.Start();
            section.Start();

            var requests = _eligibleTrademarkItems.Retrieve(caseIds)
                                         .Select(c => new TrademarkDataRequest
                                          {
                                              ClientIndex = c.CaseKey.ToString(),
                                              ApplicationNumber = c.ApplicationNumber,
                                              ApplicationDate = c.ApplicationDate.DateOrNull(),
                                              PublicationNumber = c.PublicationNumber,
                                              PublicationDate = c.PublicationDate.DateOrNull(),
                                              RegistrationNumber = c.RegistrationNumber,
                                              RegistrationDate = c.RegistrationDate.DateOrNull(),
                                              CountryCode = c.CountryCode,
                                              ExpirationDate = c.ExpirationDate.DateOrNull(),
                                              TerminationDate = c.TerminationDate.DateOrNull(),
                                              PriorityNumber = c.PriorityNumber,
                                              PriorityDate = c.PriorityDate.DateOrNull(),
                                              PriorityCountry = c.PriorityCountry
                                          }).ToArray();

            message.AppendLine($"{section.Elapsed} to build request from data.");
            section.Restart();

            var response = await _matchingClient.MatchingApi(requests);

            var idResponse = response.Result.ToDictionary(k => int.Parse(k.ClientIndex), v => v);

            var dvRequests = _requestMapping.MapRequests(response.Result, requests);

            var workflow = new List<Activity>();

            var innographyDataResults = await _dvClient.ValidationApi(dvRequests);

            var idDataResults = innographyDataResults.Result.ToDictionary(k => int.Parse(k.ClientIndex), v => v);

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
                                     return r.HasInvalidInnographyId();
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
                              var isMatch = idDataResults[c.Case.CaseKey].IsHighConfidenceMatch();
                              var ipid = idDataResults[c.Case.CaseKey].IpId;
                              var path = _dataDownloadLocationResolver.Resolve(c);
                              return Activity.Sequence(
                                                       Activity.Run<IDownloadedCase>(_ => _.Process(c, isMatch)),
                                                       Activity.Run<IInnographyTrademarksImage>(_ => _.Download(c.Case, path, ipid, false)))
                                                    .ExceptionFilter<ErrorLogger>((ex, e) => e.Log(ex, c))
                                                    .AnyFailed(Activity.Run<IDownloadFailedNotification>(d => d.Notify(c)))
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

                _logger.Warning($"This Innography schedule for Trademarks ({sessionGuid}) took {timeTaken.Elapsed}", message.ToString());
            }

            return Activity.Sequence(workflow);
        }
    }
}
