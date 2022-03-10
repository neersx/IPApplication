using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Notifications;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.PctOneTimeJob
{
    class PctCasesCleanUp : IPerformBackgroundJob
    {
        readonly ICaseNotifications _caseNotifications;

        public PctCasesCleanUp(ICaseNotifications caseNotifications)
        {
            _caseNotifications = caseNotifications;
        }

        public string Type => "PctCasesCleanUp";

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<PctCasesCleanUp>(b => b.Execute(jobExecutionId));
        }

        public Task<Activity> Execute(long jobExecutionId)
        {
            var work = ChunkedExecution().ToArray();

            if (!work.Any())
                return Task.FromResult(DefaultActivity.NoOperation());

            var workflow = Activity
                .Sequence(work)
                .AnyFailed(DefaultActivity.NoOperation())
                .ThenContinue();

            return Task.FromResult(workflow);
        }

        public IEnumerable<Activity> ChunkedExecution()
        {
            var searchParams = new SearchParameters
                {
                    DataSourceTypes = new[] { DataSourceType.UsptoPrivatePair },
                    IncludeReviewed = true,
                    IncludeErrors = false
                };

            var notifications = _caseNotifications.ThatSatisfies(searchParams).Select(_ => _.Id).ToList();

            const int chunkSize = 1000;
            var currentChunk = notifications.Take(chunkSize).ToArray();

            while (currentChunk.Any())
            {
                notifications = notifications.Except(currentChunk).ToList();

                var chunk = currentChunk.ToList();
                yield return Activity.Run<PctCasesCleanUp>(fc => fc.CheckAndUpdatePctCases(chunk));

                currentChunk = notifications.Take(chunkSize).ToArray();
            }
        }

        public Task<Activity> CheckAndUpdatePctCases(List<int> notificationIds)
        {
            var activities = notificationIds.Select(notificationId => Activity.Sequence(
                                           Activity.Run<CheckPctCase>(c => c.CheckAndUpdateCase(notificationId))
                                          .ThenContinue()));

            return Task.FromResult((Activity)Activity.Sequence(activities));
        }
    }
}
