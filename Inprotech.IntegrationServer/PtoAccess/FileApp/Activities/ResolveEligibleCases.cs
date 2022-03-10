using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class ResolveEligibleCases
    {
        readonly ICasesEligibleForDownload _casesEligibleForDownload;
        readonly IDownloadCaseDispatcher _downloadCaseDispatcher;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IBufferedStringWriter _bufferedStringWriter;
        readonly IFileSettingsResolver _fileSettingsResolver;
        readonly IFileApiClient _apiClient;

        public ResolveEligibleCases(ICasesEligibleForDownload casesEligibleForDownload, 
            IDownloadCaseDispatcher downloadCaseDispatcher,
            IDataDownloadLocationResolver dataDownloadLocationResolver,
            IBufferedStringWriter bufferedStringWriter,
            IFileSettingsResolver fileSettingsResolver,
            IFileApiClient apiClient)
        {
            _casesEligibleForDownload = casesEligibleForDownload;
            _downloadCaseDispatcher = downloadCaseDispatcher;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _bufferedStringWriter = bufferedStringWriter;
            _fileSettingsResolver = fileSettingsResolver;
            _apiClient = apiClient;
        }

        public async Task<Activity> From(DataDownload session, int? savedQueryId, int? executeAs)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            if (savedQueryId == null) throw new ArgumentNullException(nameof(savedQueryId));
            if (executeAs == null) throw new ArgumentNullException(nameof(executeAs));

            var fileSetting = _fileSettingsResolver.Resolve();

            var fileCases = (await _apiClient.Get<IEnumerable<FileCase>>(fileSetting.CasesApi(), NotFoundHandling.Throw404)).ToArray();

            var path = _dataDownloadLocationResolver.ResolveRoot(session, "applicationlist.json");

            await _bufferedStringWriter.Write(path, JsonConvert.SerializeObject(fileCases));

            return await _casesEligibleForDownload.ResolveAsync(
                                                                session,
                                                                savedQueryId.Value,
                                                                executeAs.Value,
                                                                _downloadCaseDispatcher.Dispatch);
        }
    }
}