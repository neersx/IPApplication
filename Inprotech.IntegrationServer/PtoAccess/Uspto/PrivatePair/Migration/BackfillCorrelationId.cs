using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.ExternalCaseResolution;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Migration
{
    public class BackfillCorrelationId : IPerformBackgroundJob
    {
        readonly IRepository _repository;
        readonly IPrivatePairCases _privatePairCases;

        public BackfillCorrelationId(IRepository repository, IPrivatePairCases privatePairCases)
        {
            _repository = repository;
            _privatePairCases = privatePairCases;
        }

        public Task<Activity> Now(long jobExecutionId)
        {
            var work = Find().ToArray();

            if (!work.Any())
                return Task.FromResult(DefaultActivity.NoOperation());

            var workflow = Activity
                .Sequence(work)
                .AnyFailed(DefaultActivity.NoOperation()) /* carry on */
                .ThenContinue();

            return Task.FromResult(workflow);
        }

        IEnumerable<Activity> Find()
        {
            var orphaned =
                _repository.Set<Case>()
                    .Where(_ => !_.CorrelationId.HasValue)
                    .ToList();

            const int chunkSize = 1000;

            var currentChunk = orphaned.Take(chunkSize).ToArray();
            while (currentChunk.Any())
            {
                orphaned = orphaned.Except(currentChunk).ToList();

                var chunk = currentChunk.Select(_ => _.Id).ToArray();
                yield return Activity.Run<BackfillCorrelationId>(_ => _.ThisChunk(chunk));

                currentChunk = orphaned.Take(chunkSize).ToArray();
            }
        }

        public Task<Activity> ThisChunk(IEnumerable<int> integrationCaseIds)
        {
            var ids = integrationCaseIds.ToArray();

            var resolved = _privatePairCases.Resolve(ids, true); /* start with exact match */

            var establishLink = Activity.Run<BackfillCorrelationId>(_ => _.Update(resolved));

            var unresolved = ids.Except(resolved.Keys).ToArray();

            if (unresolved.Any())
            {
                var fuzzyMatchRemainder = Activity.Run<BackfillCorrelationId>(_ => _.FuzzyMatchRemainder(unresolved));
                return Task.FromResult((Activity) Activity.Sequence(establishLink, fuzzyMatchRemainder));
            }

            return Task.FromResult((Activity) establishLink);
        }

        public Task<Activity> FuzzyMatchRemainder(IEnumerable<int> integrationCaseIds)
        {
            var ids = integrationCaseIds.ToArray();

            var resolved = _privatePairCases.Resolve(ids, false);

            var establishLink = Activity.Run<BackfillCorrelationId>(_ => _.Update(resolved));

            return Task.FromResult((Activity) establishLink);
        }

        public Task Update(Dictionary<int, int> resolved)
        {
            var r = resolved.Keys;
            var integrationCases = _repository.Set<Case>()
                .Where(_ => r.Contains(_.Id) && _.CorrelationId == null);

            foreach (var integrationCase in integrationCases)
            {
                if (resolved.TryGetValue(integrationCase.Id, out int correlationId))
                    integrationCase.CorrelationId = correlationId;
            }

            _repository.SaveChanges();

            return Done();
        }

        static Task Done()
        {
            return Task.FromResult<object>(null);
        }

        public string Type => "BackFillCorrelationId";

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<BackfillCorrelationId>(b => b.Now(jobExecutionId));
        }
    }
}