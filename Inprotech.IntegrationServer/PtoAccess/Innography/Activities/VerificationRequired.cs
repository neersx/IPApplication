using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Search.Export;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Jobs;
using Newtonsoft.Json;
using Activity = Dependable.Activity;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public class VerificationRequired
    {
        readonly IBufferedStringReader _bufferedStringReader;
        readonly IJobArgsStorage _jobArgsStorage;

        public VerificationRequired(IBufferedStringReader bufferedStringReader,
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

            var patentsData = cases.Where(_ => _.Case.PropertyType != KnownPropertyTypes.TradeMark).ToArray();
            var trademarksData = cases.Where(_ => _.Case.PropertyType == KnownPropertyTypes.TradeMark).ToArray();
            var session = cases.First();
            
            var ongoingVerificationActivity = new List<Activity>();
            if (patentsData.Any())
            {
                var patentsStorageId = await _jobArgsStorage.CreateAsync(patentsData);

                ongoingVerificationActivity.Add( Activity.Sequence(Activity.Run<IPatentsVerification>(_ => _.Process(patentsStorageId)),
                                                Activity.Run<IJobArgsStorage>(_ => _.CleanUpTempStorage(patentsStorageId)))
                                             .ExceptionFilter<ErrorLogger>((ex, e) => e.Log(ex, session)).ThenContinue());
            }

            if (trademarksData.Any())
            {
                var trademarksStorageId = await _jobArgsStorage.CreateAsync(trademarksData);

                ongoingVerificationActivity.Add(Activity.Sequence(Activity.Run<ITrademarksVerification>(_ => _.Process(trademarksStorageId)),
                                             Activity.Run<IJobArgsStorage>(_ => _.CleanUpTempStorage(trademarksStorageId)))
                                             .ExceptionFilter<ErrorLogger>((ex, e) => e.Log(ex, session)).ThenContinue());
            }

            return Activity.Sequence(ongoingVerificationActivity);
        }
    }
}