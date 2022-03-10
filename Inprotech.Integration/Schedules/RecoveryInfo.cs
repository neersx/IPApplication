using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

namespace Inprotech.Integration.Schedules
{
    public class RecoveryInfo
    {
        public RecoveryInfo()
        {
            CaseIds = Enumerable.Empty<int>();
            ScheduleRecoverableIds = Enumerable.Empty<long>();
            DocumentIds = Enumerable.Empty<int>();
            OrphanedDocumentIds = Enumerable.Empty<int>();
            CaseWithoutArtifactId = Enumerable.Empty<FailedItem>();
        }

        public string CorrelationId { get; set; }

        public IEnumerable<int> CaseIds { get; set; }

        public IEnumerable<long> ScheduleRecoverableIds { get; set; }

        public IEnumerable<int> DocumentIds { get; set; }

        public IEnumerable<int> OrphanedDocumentIds { get; set; }

        public IEnumerable<FailedItem> CaseWithoutArtifactId { get; set; }

        public bool IsEmpty => !CaseIds.Any() && !ScheduleRecoverableIds.Any() && !DocumentIds.Any();
    }

    public static class RecoveryInfoExtension
    {
        public static bool IsEmpty(this IEnumerable<RecoveryInfo> recoveryInfos)
        {
            return recoveryInfos.All(_ => _.IsEmpty);
        }

        public static IEnumerable<string> CorrelationshipOf(this IEnumerable<RecoveryInfo> recoveryInfos, int? caseId, int? documentId)
        {
            var correlationIds = new List<string>();

            foreach (var recoveryInfo in recoveryInfos)
            {
                if (caseId.HasValue && recoveryInfo.CaseIds.Contains(caseId.Value))
                    correlationIds.Add(recoveryInfo.CorrelationId);

                if (documentId.HasValue && recoveryInfo.DocumentIds.Contains(documentId.Value))
                    correlationIds.Add(recoveryInfo.CorrelationId);
            }

            return correlationIds.Distinct();
        }

        public static string AsString(this IEnumerable<string> correlatedIds)
        {
            var withoutEmpty = correlatedIds.Except(new[] {null, string.Empty}).ToArray();

            var result = string.Join(",", withoutEmpty.ToArray());

            return string.IsNullOrWhiteSpace(result) ? null : result;
        }

        public static IEnumerable<RecoveryInfo> Load(this string recoveryInfo)
        {
            try
            {
                return JsonConvert.DeserializeObject<IEnumerable<RecoveryInfo>>(recoveryInfo);
            }
            catch (JsonException)
            {
                return new[] {JsonConvert.DeserializeObject<RecoveryInfo>(recoveryInfo)};
            }
        }
    }
}