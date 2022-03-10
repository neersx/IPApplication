using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Activities
{
    public interface ICasesEligibleForDownload
    {
        Task<ActivityGroup> ResolveAsync(DataDownload session, int savedQueryId, int executeAs, Func<DataDownload[], Task<Activity>> createDownloadActivity);
    }

    public class CasesEligibleForDownload : ICasesEligibleForDownload
    {
        readonly IArtifactsService _artefactsService;
        readonly IChunckedDownloadRequests _chunckedDownloadRequests;
        readonly IEligibleCases _eligibleCases;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;
        readonly ICommonSettings _settings;

        public CasesEligibleForDownload(IEligibleCases eligibleCases, ICommonSettings settings,
                                        IArtifactsService artefactsService,
                                        IScheduleRuntimeEvents scheduleRuntimeEvents,
                                        IChunckedDownloadRequests chunckedDownloadRequests)
        {
            _eligibleCases = eligibleCases;
            _settings = settings;
            _artefactsService = artefactsService;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _chunckedDownloadRequests = chunckedDownloadRequests;
        }
        
        public async Task<ActivityGroup> ResolveAsync(DataDownload session, int savedQueryId, int executeAs, Func<DataDownload[], Task<Activity>> createDownloadActivity)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            if (createDownloadActivity == null) throw new ArgumentNullException(nameof(createDownloadActivity));

            var chunkSize = _settings.GetChunkSize(session.DataSourceType);

            var sourceCases = _eligibleCases.Resolve(session, savedQueryId, executeAs);

            var cases = sourceCases
                .Select(_ => new DataDownload
                             {
                                 Case = _,
                                 Id = session.Id,
                                 Name = session.Name,
                                 DataSourceType = session.DataSourceType,
                                 DownloadType = session.DownloadType,
                                 ScheduleId = session.ScheduleId
                             })
                .ToList();

            var executionArtefacts = await _artefactsService.Compress("caselist.json", JsonConvert.SerializeObject(cases, Formatting.Indented));

            _scheduleRuntimeEvents.IncludeCases(session.Id, cases.Count, executionArtefacts);

            var chunks = (await _chunckedDownloadRequests.DispatchAsync(cases, chunkSize, createDownloadActivity)).ToArray();

            return Activity.Sequence(chunks);
        }
    }
}