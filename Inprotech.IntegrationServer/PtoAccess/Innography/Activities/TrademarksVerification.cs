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
    public interface ITrademarksVerification
    {
        Task<Activity> Process(long storageId);
    }

    public class TrademarksVerification : ITrademarksVerification
    {
        readonly IEligibleTrademarkItems _eligibleTrademarkItems;
        readonly IInnographyTradeMarksDataValidationClient _innographyDataValidationClient;
        readonly IJobArgsStorage _jobArgsStorage;
        readonly IBackgroundProcessLogger<TrademarksVerification> _logger;
        
        public TrademarksVerification(IEligibleTrademarkItems eligibleTrademarkItems,
                                      IInnographyTradeMarksDataValidationClient innographyDataValidationClient,
                                      IJobArgsStorage jobArgsStorage,
                                      IBackgroundProcessLogger<TrademarksVerification> logger)
        {
            _eligibleTrademarkItems = eligibleTrademarkItems;
            _innographyDataValidationClient = innographyDataValidationClient;
            _jobArgsStorage = jobArgsStorage;
            _logger = logger;
        }
        public async Task<Activity> Process(long storageId)
        {
            var cases = await _jobArgsStorage.GetAsync<DataDownload[]>(storageId);

            var caseIds = cases.Select(_ => _.Case.CaseKey).ToArray();

            var message = new StringBuilder();

            message.AppendLine($"Processing {caseIds.Length} cases");

            var timeTaken = new Stopwatch();
            var section = new Stopwatch();

            timeTaken.Start();
            section.Start();
            
            var trademarksRequest = _eligibleTrademarkItems.Retrieve(caseIds)
                                                   .Select(c => new TrademarkDataValidationRequest
                                                   {
                                                       IpId = c.IpId,
                                                       ClientIndex = c.CaseKey.ToString(),
                                                       ApplicationNumber = c.ApplicationNumber,
                                                       ApplicationDate = c.ApplicationDate.DateOrNull(),
                                                       PublicationNumber = c.PublicationNumber,
                                                       PublicationDate = c.PublicationDate.DateOrNull(),
                                                       RegistrationNumber = c.RegistrationNumber,
                                                       RegistrationDate = c.RegistrationDate.DateOrNull(),
                                                       ExpirationDate = c.ExpirationDate.DateOrNull(),
                                                       TerminationDate = c.TerminationDate.DateOrNull(),
                                                       CountryCode = c.CountryCode,
                                                       PriorityDate = c.PriorityDate.DateOrNull(),
                                                       PriorityNumber = c.PriorityNumber,
                                                       PriorityCountry = c.PriorityCountry
                                                   }).ToArray();

            message.AppendLine($"{section.Elapsed} to build request from data for verification.");
            section.Restart();

            var innographyDataResults = await _innographyDataValidationClient.ValidationApi(trademarksRequest);

            message.AppendLine($"{section.Elapsed} to receive request from Innography.");
            section.Stop();

            var verificationResults = (from r in innographyDataResults.Result
                                       join c in cases on new {CaseKey = r.ClientIndex} equals new {CaseKey = c.Case.CaseKey.ToString()} into c1
                                       from c in c1
                                       select c.WithExtendedDetails(r)).ToArray();

            var sessionGuid = cases.First().Id;

            var workflow = verificationResults
                           .Select(c =>
                                       Activity.Run<IDownloadedCase>(_ => _.Process(c, false))
                                               .ExceptionFilter<ErrorLogger>((ex, e) => e.Log(ex, c))
                                               .Failed(Activity.Run<IDownloadFailedNotification>(d => d.Notify(c)))
                                               .ThenContinue())
                           .ToArray();

            timeTaken.Stop();

            if (timeTaken.Elapsed.TotalSeconds > 10)
            {
                message.AppendLine($"Initial={cases.Length}");
                message.AppendLine($"Sent={trademarksRequest.Length}");
                message.AppendLine($"Received={verificationResults.Length}");

                _logger.Warning($"This Innography schedule for Trademarks ({sessionGuid}) took {timeTaken.Elapsed}", message.ToString());
            }

            return Activity.Sequence(workflow);
        }
    }
}
