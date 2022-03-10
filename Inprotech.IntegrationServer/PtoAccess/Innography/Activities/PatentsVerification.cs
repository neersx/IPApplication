﻿using System.Diagnostics;
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
    public interface IPatentsVerification
    {
        Task<Activity> Process(long storageId);
    }

    public class PatentsVerification : IPatentsVerification
    {
        readonly IEligiblePatentItems _eligiblePatentItems;
        readonly IInnographyPatentsDataValidationClient _innographyDataValidationClient;
        readonly IJobArgsStorage _jobArgsStorage;
        readonly IBackgroundProcessLogger<PatentsVerification> _logger;

        public PatentsVerification(IEligiblePatentItems eligiblePatentItems,
                                   IInnographyPatentsDataValidationClient innographyDataValidationClient,
                                   IJobArgsStorage jobArgsStorage,
                                   IBackgroundProcessLogger<PatentsVerification> logger)
        {
            _eligiblePatentItems = eligiblePatentItems;
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
            
            var patentsRequest = _eligiblePatentItems.Retrieve(caseIds)
                                                   .Select(c => new PatentDataValidationRequest
                                                   {
                                                       IpId = c.IpId,
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
                                                       PriorityDate = c.PriorityDate.DateOrNull(),
                                                       PriorityNumber = c.PriorityNumber,
                                                       PriorityCountry = c.PriorityCountry
                                                   }).ToArray();

            message.AppendLine($"{section.Elapsed} to build request from data for verification.");
            section.Restart();

            var innographyDataResults = await _innographyDataValidationClient.ValidationApi(patentsRequest);

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
                message.AppendLine($"Sent={patentsRequest.Length}");
                message.AppendLine($"Received={verificationResults.Length}");

                _logger.Warning($"This Innography schedule for Patents ({sessionGuid}) took {timeTaken.Elapsed}", message.ToString());
            }

            return Activity.Sequence(workflow);
        }
    }
}
