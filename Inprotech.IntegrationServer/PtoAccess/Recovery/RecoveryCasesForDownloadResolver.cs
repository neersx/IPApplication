using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

namespace Inprotech.IntegrationServer.PtoAccess.Recovery
{
    public class RecoveryCasesForDownloadResolver : IResolveCasesForDownload
    {
        readonly IManageRecoveryInfo _recoveryInfoManager;
        readonly IRepository _repository;
        readonly IReadScheduleSettings _scheduleSettingsReader;

        public RecoveryCasesForDownloadResolver(IReadScheduleSettings scheduleSettingsReader,
                                                IManageRecoveryInfo recoveryInfoManager, IRepository repository)
        {
            _scheduleSettingsReader = scheduleSettingsReader;
            _recoveryInfoManager = recoveryInfoManager;
            _repository = repository;
        }

        public IEnumerable<int> GetCaseIds(DataDownload session, int savedQueryId, int executeAs)
        {
            var settingsId = _scheduleSettingsReader.GetTempStorageId(session.ScheduleId);
            var recoveryInfo = _recoveryInfoManager.GetIds(settingsId).Single();

            return _repository.Set<Case>()
                              .Where(c => recoveryInfo.CaseIds.Contains(c.Id) && c.CorrelationId.HasValue)
                              .Select(c => c.CorrelationId.Value)
                              .ToArray()
                              .Select(cid => cid)
                              .ToArray();
        }
    }
}