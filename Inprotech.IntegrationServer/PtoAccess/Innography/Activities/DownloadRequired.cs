using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Search.Export;
using InprotechKaizen.Model.Components.Integration.Jobs;
using Newtonsoft.Json;
using Activity = Dependable.Activity;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public class DownloadRequired
    {
        readonly IBufferedStringReader _bufferedStringReader;
        readonly IJobArgsStorage _jobArgsStorage;

        public DownloadRequired(IBufferedStringReader bufferedStringReader,
                                    IJobArgsStorage jobArgsStorage)
        {
            _bufferedStringReader = bufferedStringReader;
            _jobArgsStorage = jobArgsStorage;
        }

        public async Task<Activity> FromInnography(string path)
        {
            if (path == null) throw new ArgumentNullException(nameof(path));

            var data = await _bufferedStringReader.Read(path);

            var cases = JsonConvert.DeserializeObject<DataDownload[]>(data);

            var patentsData = cases.Where(_ => _.IsPatentsDataValidation()).ToArray();
            var trademarksData = cases.Where(_ => _.IsTrademarkDataValidation()).ToArray();
            var session = cases.First();
            
            var downloadActivity = new List<Activity>();
            if (patentsData.Any())
            {
                var patentsStorageId = await _jobArgsStorage.CreateAsync(patentsData);

                downloadActivity.Add(Activity.Sequence(
                                                       Activity.Run<IPatentsDownload>(_ => _.Process(patentsStorageId)),
                                                       Activity.Run<IJobArgsStorage>(_ => _.CleanUpTempStorage(patentsStorageId)))
                                             .ExceptionFilter<ErrorLogger>((ex, e) => e.Log(ex, session)).ThenContinue());
            }

            if (trademarksData.Any())
            {
                var trademarksStorageId = await _jobArgsStorage.CreateAsync(trademarksData);

                downloadActivity.Add(Activity.Sequence(
                                                       Activity.Run<ITrademarksDownload>(_ => _.Process(trademarksStorageId)),
                                                       Activity.Run<IJobArgsStorage>(_ => _.CleanUpTempStorage(trademarksStorageId)))
                                             .ExceptionFilter<ErrorLogger>((ex, e) => e.Log(ex, session)).ThenContinue());
            }

            return Activity.Sequence(downloadActivity);
        }
    }
}