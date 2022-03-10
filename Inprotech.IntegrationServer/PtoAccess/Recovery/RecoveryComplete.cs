using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

namespace Inprotech.IntegrationServer.PtoAccess.Recovery
{
    public class RecoveryComplete
    {
        readonly IManageRecoveryInfo _recoveryInfoManager;
        readonly IRepository _repository;
        readonly IReadScheduleSettings _scheduleSettingsReader;

        public RecoveryComplete(IManageRecoveryInfo recoveryInfoManager, IRepository repository,
            IReadScheduleSettings scheduleSettingsReader)
        {
            _recoveryInfoManager = recoveryInfoManager;
            _repository = repository;
            _scheduleSettingsReader = scheduleSettingsReader;
        }

        public Task Complete(int scheduleId)
        {
            return CompleteCorrelated(string.Empty, scheduleId);
        }

        public Task CompleteCorrelated(string correlationId, int scheduleId)
        {
            using (var transaction = _repository.BeginTransaction())
            {
                var storageId = _scheduleSettingsReader.GetTempStorageId(scheduleId);

                var recoveryInfos = _recoveryInfoManager.GetIds(storageId).ToArray();

                var recoveryInfo = string.IsNullOrWhiteSpace(correlationId)
                    ? recoveryInfos.Single()
                    : recoveryInfos.Single(_ => _.CorrelationId == correlationId);

                recoveryInfos = recoveryInfos.Except(new[] {recoveryInfo}).ToArray();

                _repository.Set<ScheduleRecoverable>()
                    .Where(sr => recoveryInfo.ScheduleRecoverableIds.Contains(sr.Id))
                    .ToList()
                    .ForEach(_ => { _repository.Set<ScheduleRecoverable>().Remove(_); }
                    );

                if (recoveryInfos.Any())
                {
                    /* this may be executed by a competing thread for a different correlationId 
                       against the same storage.  The rowversion in TempStorage should handle this 
                       and the activity will be re-executed by the dependable runtime. */
                    _recoveryInfoManager.UpdateIds(storageId, recoveryInfos);
                }
                else
                {
                    _recoveryInfoManager.DeleteIds(storageId);
                }

                _repository.SaveChanges();

                transaction.Complete();
            }

            return Task.FromResult(0);
        }
    }
}