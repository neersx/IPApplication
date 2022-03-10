using System;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess.Activities;

#pragma warning disable CS1998 // Async "From" method lacks 'await' operators and will run synchronously

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class ResolveEligibleCases
    {
        readonly ICasesEligibleForDownload _casesEligibleForDownload;
        
        public ResolveEligibleCases(ICasesEligibleForDownload casesEligibleForDownload)
        {
            _casesEligibleForDownload = casesEligibleForDownload;
        }

        public async Task<Activity> From(DataDownload session, int savedQueryId, int executeAs)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));

            return await _casesEligibleForDownload.ResolveAsync(
                session, 
                savedQueryId, 
                executeAs,
                _ =>
                {
                    return Task.FromResult( (Activity) Activity.Run<DownloadRequired>(r => r.Dispatch(_)));
                });
        }
    }
}