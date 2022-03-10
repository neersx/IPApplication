using System;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.Activities
{
    public class ResolveEligibleCases
    {
        readonly ICasesEligibleForDownload _casesEligibleForDownload;

        public ResolveEligibleCases(ICasesEligibleForDownload casesEligibleForDownload)
        {
            _casesEligibleForDownload = casesEligibleForDownload;
        }
        
        public async Task<Activity> From(DataDownload session, int? savedQueryId, int? executeAs)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            if (savedQueryId == null) throw new ArgumentNullException(nameof(savedQueryId));
            if (executeAs == null) throw new ArgumentNullException(nameof(executeAs));

            return await _casesEligibleForDownload.ResolveAsync(
                session,
                savedQueryId.Value,
                executeAs.Value,
                DownloadCaseDispatcher);
        }

        static Task<Activity> DownloadCaseDispatcher(DataDownload[] cases)
        {
            return Task.FromResult((Activity) Activity.Run<DownloadRequired>(r => r.Dispatch(cases)));
        }
    }
}