using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Integration.Schedules
{
    public interface IRecoverableItems
    {
        IEnumerable<RecoveryInfo> FindBySchedule(int scheduleId);
        IEnumerable<RecoveryInfo> FindByDataType(DataSourceType type);
    }

    public class RecoverableItems : IRecoverableItems
    {
        readonly IScheduleRecoverableReader _scheduleRecoverableReader;

        public RecoverableItems(IScheduleRecoverableReader scheduleRecoverableReader)
        {
            _scheduleRecoverableReader = scheduleRecoverableReader;
        }

        public IEnumerable<RecoveryInfo> FindByDataType(DataSourceType type)
        {
            var allFailedItems = _scheduleRecoverableReader
                                 .GetAll()
                                 .Where(_ => _.DataSourceType == type)
                                 .ToArray();
            return FindAllRelevent(allFailedItems);
        }

        public IEnumerable<RecoveryInfo> FindBySchedule(int scheduleId)
        {
            var allFailedItems = _scheduleRecoverableReader
                                 .GetAll()
                                 .Where(_ => _.ScheduleId == scheduleId)
                                 .ToArray();

            return FindAllRelevent(allFailedItems);
        }

        IEnumerable<RecoveryInfo> FindAllRelevent(IEnumerable<FailedItem> allFailedItems)
        {
            var relatedCases = Enumerable.Empty<FailedItem>();
            var orphanedDocs = _scheduleRecoverableReader.OrphanDocuments(allFailedItems, OrphanDocumentsReaderMode.ForRecovery, out relatedCases)
                                                         .GroupBy(_ => _.CorrelationId)
                                                         .ToDictionary(_ => _.Key);

            var grouped = allFailedItems.Union(relatedCases).GroupBy(_ => _.CorrelationId);

            foreach (var item in grouped)
            {
                var orphanedDocuments = orphanedDocs.ContainsKey(item.Key) ? orphanedDocs[item.Key].Where(_ => _.ArtifactType == ArtifactType.Document) : Enumerable.Empty<FailedItem>();
                yield return new RecoveryInfo
                {
                    CorrelationId = item.Key == "*" ? null : item.Key,
                    CaseIds = item.Where(_ => _.ArtifactType == ArtifactType.Case).Where(_ => _.ArtifactId != null).Select(_ => (int) _.ArtifactId).Distinct(),
                    ScheduleRecoverableIds = item.Where(_ => _.Id != null).Select(_ => (long) _.Id).Distinct(),
                    DocumentIds = item.Where(_ => _.ArtifactType == ArtifactType.Document && _.ArtifactId != null).Select(_ => (int) _.ArtifactId).Distinct(),
                    OrphanedDocumentIds = orphanedDocuments.Where(_ => _.ArtifactId != null).Select(_ => (int) _.ArtifactId).Distinct(),
                    CaseWithoutArtifactId = item.Where(_ => _.ArtifactType == ArtifactType.Case).Where(_ => _.ArtifactId == null).Distinct()
                };
            }
        }
    }
}