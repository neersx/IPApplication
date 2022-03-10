using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.System.Utilities
{
    public interface ITempStorageHandler
    {
        Task<long> Add<T>(T items);
        Task<T> Get<T>(long tempStorageId);
        Task<T> Pop<T>(long tempStorageId);
        Task Remove(long tempStorageId);
    }

    public class TempStorageHandler : ITempStorageHandler
    {
        readonly IDbContext _dbContext;

        public TempStorageHandler(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<long> Add<T>(T items)
        {
            if (EqualityComparer<T>.Default.Equals(items, default))
            {
                return -1;
            }

            var dataToStore = typeof(T) == typeof(string)
                ? items as string
                : JsonConvert.SerializeObject(items);

            var tempStorage = _dbContext.Set<TempStorage.TempStorage>()
                                        .Add(new TempStorage.TempStorage(dataToStore));

            await _dbContext.SaveChangesAsync();

            return tempStorage.Id;
        }

        public async Task<T> Get<T>(long tempStorageId)
        {
            if (tempStorageId <= 0) return default;

            var tempStorage = await _dbContext.Set<TempStorage.TempStorage>()
                                              .SingleOrDefaultAsync(_ => _.Id == tempStorageId);

            return tempStorage != null
                ? typeof(T) == typeof(string)
                    ? (T) Convert.ChangeType(tempStorage.Value, typeof(T))
                    : JsonConvert.DeserializeObject<T>(tempStorage.Value)
                : default;
        }

        public async Task<T> Pop<T>(long tempStorageId)
        {
            var r = await Get<T>(tempStorageId);

            await Remove(tempStorageId);

            return r;
        }

        public async Task Remove(long tempStorageId)
        {
            await _dbContext.DeleteAsync(_dbContext.Set<TempStorage.TempStorage>().Where(_ => _.Id == tempStorageId));
        }
    }
}