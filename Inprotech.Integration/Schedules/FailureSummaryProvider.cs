using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Extensions;

namespace Inprotech.Integration.Schedules
{
    public interface IFailureSummaryProvider
    {
        IEnumerable<FailedItemsSummary> RecoverableItemsByDataSource(DataSourceType[] dataSourceTypes, ArtifactInclusion artefactInclusionOption);

        IEnumerable<FailedItem> AllFailedItems(DataSourceType[] dataSourceTypes, ArtifactInclusion artefactInclusionOption);

        Task<IEnumerable<object>> AllUnrecoverableArtifacts(ArtifactInclusion artifactInclusionOption);
    }

    public class FailureSummaryProvider : IFailureSummaryProvider
    {
        readonly IIndex<DataSourceType, IScheduleMessages> _scheduleMessages;
        readonly IScheduleRecoverableReader _scheduleRecoverableReader;

        public FailureSummaryProvider(IScheduleRecoverableReader scheduleRecoverableReader, IIndex<DataSourceType, IScheduleMessages> scheduleMessages)
        {
            _scheduleRecoverableReader = scheduleRecoverableReader;
            _scheduleMessages = scheduleMessages;
        }

        public IEnumerable<FailedItemsSummary> RecoverableItemsByDataSource(DataSourceType[] dataSourceTypes, ArtifactInclusion artifactInclusionOption)
        {
            var allFailedItems = AllFailedItems(dataSourceTypes, artifactInclusionOption).ToArray();
            var failedScheduleDetails = _scheduleRecoverableReader.GetFailedScheduleDetails(allFailedItems)
                                                                  .ToArray();
            var allFailedDocs = _scheduleRecoverableReader.GetAll(artifactInclusionOption).Where(_ => _.ArtifactType == ArtifactType.Document).ToList();

            var downloadListArtifacts = _scheduleRecoverableReader.DownloadListArtefacts(allFailedItems, artifactInclusionOption)
                                                                  .ToArray();

            var grouped = allFailedItems.GroupBy(_ => _.DataSourceType)
                                        .ToDictionary(_ => _.Key);
            var groupedDocs = allFailedDocs.GroupBy(_ => _.DataSourceType)
                                           .ToDictionary(_ => _.Key);
            foreach (var dataSource in dataSourceTypes)
            {
                var source1 = dataSource;
                var details = new FailedItemsSummary
                {
                    DataSource = dataSource.ToString(),
                    Cases = grouped.ContainsKey(dataSource) ? GetFailedItemsWithCorrelationIds(grouped[dataSource]).Where(_ => _.ArtifactType == ArtifactType.Case).DistinctBy(_ => new {_.ScheduleId, _.ApplicationNumber, _.PublicationNumber, _.RegistrationNumber}) : Enumerable.Empty<FailedItem>(),
                    Documents = groupedDocs.ContainsKey(dataSource) ? groupedDocs[dataSource].Where(_ => _.ArtifactType == ArtifactType.Document).DistinctBy(_ => new {_.ArtifactId, _.ArtifactType}) : Enumerable.Empty<FailedItem>(),
                    Schedules = failedScheduleDetails.Where(_ => _.DataSource == source1),
                    IndexList = downloadListArtifacts.Where(_ => _.DataSourceType == dataSource)
                };

                details.RecoverPossible = details.Schedules.Any(_ => _.RecoveryStatus == RecoveryScheduleStatus.Idle);
                details.FailedCount = details.Cases.DistinctBy(_ => new {_.ArtifactId, _.ArtifactType}).Count();
                details.FailedDocumentCount = details.Documents.DistinctBy(_ => new {_.ArtifactId, _.ArtifactType}).Count();
                foreach (var detailsSchedule in details.Schedules) detailsSchedule.FailedDocumentsCount = details.Documents.Count(_ => _.ScheduleId == detailsSchedule.ScheduleId || detailsSchedule.AggregateFailures);
                if (_scheduleMessages.TryGetValue(dataSource, out var resolver))
                {
                    details.ScheduleMessages = resolver.Resolve(details.Schedules.Select(_ => _.ScheduleId)).DistinctBy(_ => _.Message);
                }

                yield return details;
            }
        }

        public IEnumerable<FailedItem> AllFailedItems(DataSourceType[] dataSourceTypes, ArtifactInclusion artifactInclusionOption)
        {
            return _scheduleRecoverableReader.GetAllFor(dataSourceTypes, artifactInclusionOption)
                                             .DistinctBy(_ => new {_.ArtifactId, _.ArtifactType, _.ScheduleId, _.CorrelationId});
        }

        public async Task<IEnumerable<object>> AllUnrecoverableArtifacts(ArtifactInclusion artifactInclusionOption)
        {
            return await _scheduleRecoverableReader.GetAllUnrecoverableArtifacts(artifactInclusionOption);
        }

        static IEnumerable<FailedItem> GetFailedItemsWithCorrelationIds(IEnumerable<FailedItem> failedItems)
        {
            foreach (var c in failedItems.GroupBy(_ => new {_.ScheduleId, _.ArtifactId, _.ArtifactType}))
            {
                var selectedCase = c.First();
                selectedCase.CorrelationIds = string.Join(", ", c.Where(_ => !string.IsNullOrEmpty(_.CorrelationId) && _.CorrelationId != "*")
                                                                 .Select(_ => _.CorrelationId)
                                                                 .Distinct());

                yield return selectedCase;
            }
        }
    }
}