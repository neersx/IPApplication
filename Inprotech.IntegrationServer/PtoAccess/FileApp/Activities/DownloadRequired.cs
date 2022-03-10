using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Newtonsoft.Json;

// ReSharper disable InconsistentNaming

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class DownloadRequired
    {
        readonly IBufferedStringReader _bufferedStringReader;
        readonly IFileInstructAllowedCases _fileInstructAllowedCases;
        readonly IFileSettingsResolver _fileSettingsResolver;

        public DownloadRequired(
            IBufferedStringReader bufferedStringReader,
            IFileSettingsResolver fileSettingsResolver,
            IFileInstructAllowedCases fileInstructAllowedCases)
        {
            _bufferedStringReader = bufferedStringReader;
            _fileSettingsResolver = fileSettingsResolver;
            _fileInstructAllowedCases = fileInstructAllowedCases;
        }

        public async Task<Activity> FromTheIPPlatform(string dataPath, string listPath)
        {
            if (dataPath == null) throw new ArgumentNullException(nameof(dataPath));

            var fileSetting = _fileSettingsResolver.Resolve();

            var dataDownloads = JsonConvert.DeserializeObject<DataDownload[]>(await _bufferedStringReader.Read(dataPath));

            var fileCases = JsonConvert.DeserializeObject<FileCase[]>(await _bufferedStringReader.Read(listPath));

            var caseIds = dataDownloads.Select(_ => _.Case.CaseKey).ToArray();

            var current = (from iac in _fileInstructAllowedCases.Retrieve(fileSetting)
                           where caseIds.Contains(iac.CaseId)
                           group iac by iac.ParentCaseId
                           into g1
                           select new
                           {
                               ParentCaseId = g1.Key,
                               Cases = g1
                           }).ToArray();

            var matches = new List<DataDownload>();

            foreach (var c in current)
            {
                var parentCaseId = c.ParentCaseId.ToString();
                var fileCase = fileCases.FirstOrDefault(_ => _.Id == parentCaseId);

                if (fileCase == null)
                {
                    continue;
                }

                foreach (var child in c.Cases)
                {
                    var dataDownload = dataDownloads.Single(_ => _.Case.CaseKey == child.CaseId);
                    if (fileCase.Countries.Any(_ => _.Code == child.CountryCode))
                    {
                        matches.Add(dataDownload.WithExtendedDetails(fileCase));
                    }
                }
            }

            var workflow = new List<Activity>();
            var matchedId = matches.Select(_ => _.Case.CaseKey);
            var itemsToDiscard = dataDownloads.Where(_ => !matchedId.Contains(_.Case.CaseKey)).ToArray();
            if (itemsToDiscard.Any())
            {
                var itemsToDiscardIds = itemsToDiscard.Select(_ => _.Case.CaseKey).ToArray();
                var sessionGuid = dataDownloads.First().Id;
                workflow.Add(Activity.Run<DetailsUnavailableOrInvalid>(_ => _.Handle(sessionGuid, itemsToDiscardIds, listPath))
                                     .ThenContinue());
            }

            var keep = matches.Select(c =>
                                          Activity.Run<DownloadedCase>(_ => _.Process(c))
                                                  .ExceptionFilter<ErrorLogger>((ex, e) => e.Log(ex, c))
                                                  .Failed(Activity.Run<IDownloadFailedNotification>(d => d.Notify(c)))
                                                  .ThenContinue())
                              .ToArray();

            if (keep.Any()) workflow.AddRange(keep);

            return Activity.Sequence(workflow);
        }
    }
}