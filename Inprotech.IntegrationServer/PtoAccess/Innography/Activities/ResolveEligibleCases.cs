using System;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public class ResolveEligibleCases
    {
        readonly ICasesEligibleForDownload _casesEligibleForDownload;
        readonly IDownloadCaseDispatcher _downloadCaseDispatcher;

        public ResolveEligibleCases(ICasesEligibleForDownload casesEligibleForDownload, IDownloadCaseDispatcher downloadCaseDispatcher)
        {
            _casesEligibleForDownload = casesEligibleForDownload;
            _downloadCaseDispatcher = downloadCaseDispatcher;
        }

        public async Task<Activity> From(DataDownload session, int? savedQueryId, int? executeAs)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            if (savedQueryId == null) throw new ArgumentNullException(nameof(savedQueryId));
            if (executeAs == null) throw new ArgumentNullException(nameof(executeAs));

            var eligibleDownloads = (session.DownloadType == DownloadType.OngoingVerification) 
                ? await _casesEligibleForDownload.ResolveAsync(
                                                                session,
                                                                savedQueryId.Value,
                                                                executeAs.Value,
                                                                _downloadCaseDispatcher.DispatchForVerification)
                : await _casesEligibleForDownload.ResolveAsync(
                                                                 session,
                                                                 savedQueryId.Value,
                                                                 executeAs.Value,
                                                                 _downloadCaseDispatcher.DispatchForMatching);

            return eligibleDownloads
                .AnyFailed(Activity.Run<ScheduleInitialisationFailure>(s => s.Notify(session)));
        }
    }
}