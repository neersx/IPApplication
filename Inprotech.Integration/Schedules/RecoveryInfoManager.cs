using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Storage;
using Newtonsoft.Json;

namespace Inprotech.Integration.Schedules
{
    public interface IManageRecoveryInfo
    {
        IEnumerable<RecoveryInfo> GetIds(long storageId);

        void DeleteIds(long storageId);

        long AddIds(IEnumerable<RecoveryInfo> ids);

        void UpdateIds(long storageId, IEnumerable<RecoveryInfo> ids);
    }

    class RecoveryInfoManager : IManageRecoveryInfo
    {
        readonly IRepository _repository;

        public RecoveryInfoManager(IRepository repository)
        {
            if (repository == null) throw new ArgumentNullException("repository");
            _repository = repository;
        }

        public IEnumerable<RecoveryInfo> GetIds(long storageId)
        {
            return _repository.Set<TempStorage>().Single(ts => ts.Id == storageId).Value.Load();
        }

        public long AddIds(IEnumerable<RecoveryInfo> ids)
        {
            var storage = _repository.Set<TempStorage>().Add(new TempStorage(JsonConvert.SerializeObject(ids)));
            _repository.SaveChanges();
            return storage.Id;
        }

        public void DeleteIds(long storageId)
        {
            var storage = _repository.Set<TempStorage>().SingleOrDefault(ts => ts.Id == storageId);
            if (storage != null)
            {
                _repository.Set<TempStorage>().Remove(storage);
            }

            _repository.SaveChanges();
        }

        public void UpdateIds(long storageId, IEnumerable<RecoveryInfo> ids)
        {
            var storage = _repository.Set<TempStorage>()
                .Single(_ => _.Id == storageId);

            storage.Value = JsonConvert.SerializeObject(ids);
            _repository.SaveChanges();
        }
    }
}