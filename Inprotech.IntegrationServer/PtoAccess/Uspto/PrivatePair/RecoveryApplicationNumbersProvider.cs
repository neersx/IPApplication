using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Recovery;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface IProvideApplicationNumbersToRecover
    {
        IEnumerable<string> GetApplicationNumbersForCustomer(Schedule schedule, string customerNumber);
    }

    public class RecoveryApplicationNumbersProvider : IProvideApplicationNumbersToRecover
    {
        readonly IReadScheduleSettings _scheduleSettingsReader;
        readonly IManageRecoveryInfo _recoveryInfoManager;
        readonly IRepository _repository;

        public RecoveryApplicationNumbersProvider(
            IReadScheduleSettings scheduleSettingsReader,
            IManageRecoveryInfo recoveryInfoManager, IRepository repository)
        {
            _scheduleSettingsReader = scheduleSettingsReader;
            _recoveryInfoManager = recoveryInfoManager;
            _repository = repository;
        }

        public IEnumerable<string> GetApplicationNumbersForCustomer(Schedule schedule, string customerNumber)
        {
            if (schedule == null) throw new ArgumentNullException(nameof(schedule));
            if (string.IsNullOrWhiteSpace(customerNumber)) throw new ArgumentNullException(nameof(customerNumber));

            var recoveryInfoId = _scheduleSettingsReader.GetTempStorageId(schedule.Id);
            var recoveryInfos = _recoveryInfoManager.GetIds(recoveryInfoId).Where(_ => _.CorrelationId == customerNumber).ToArray();
            var allCaseIds = recoveryInfos.SelectMany(_ => _.CaseIds).Distinct().ToArray();

            var orphanedDocumentIds = recoveryInfos.SelectMany(_ => _.OrphanedDocumentIds).Distinct().ToArray();

            var caseApplicationNumbers = _repository.Set<Case>()
                                                    .Where(c => allCaseIds.Contains(c.Id))
                                                    .Select(c => new
                                                                 {
                                                                     c.Id,
                                                                     c.ApplicationNumber
                                                                 })
                                                    .ToDictionary(k => k.Id, v => v.ApplicationNumber);

            var documentApplicationNumbers = _repository.Set<Document>()
                                                        .Where(_ => orphanedDocumentIds.Contains(_.Id))
                                                        .Select(d => new
                                                                     {
                                                                         d.Id,
                                                                         d.ApplicationNumber
                                                                     })
                                                        .ToDictionary(k => k.Id, v => v.ApplicationNumber);

            return
                GetApplicationNumbers(caseApplicationNumbers, recoveryInfos.SelectMany(_ => _.CaseIds))
                    .Union(GetApplicationNumbers(documentApplicationNumbers, recoveryInfos.SelectMany(_ => _.OrphanedDocumentIds))
                    .Distinct());
        }

        static IEnumerable<string> GetApplicationNumbers(Dictionary<int, string> numberMap, IEnumerable<int> relevantIds)
        {
            foreach (var id in relevantIds)
            {
                if (numberMap.TryGetValue(id, out string number))
                    yield return number;
            }
        }
    }
}