using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;
using Z.EntityFramework.Plus;

namespace InprotechKaizen.Model.Components.Integration.Jobs
{
    public interface IJobArgsStorage
    {
        Task<long> CreateAsync<T>(T jobArgs);

        Task<T> GetAsync<T>(long storageId);

        Task CleanUpTempStorage(long storageId);

        T Get<T>(long storageId);
        
        long Create<T>(T jobArgs);
        Task UpdateAsync<T>(long storageId, T jobArgs);
    }

    public class JobArgsStorage : IJobArgsStorage
    {
        readonly IDbContext _dbContext;

        public JobArgsStorage(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<long> CreateAsync<T>(T jobArgs)
        {
            var storage = _dbContext.Set<TempStorage.TempStorage>()
                                    .Add(new TempStorage.TempStorage(JsonConvert.SerializeObject(jobArgs)));
            await _dbContext.SaveChangesAsync();

            return storage.Id;
        }

        public long Create<T>(T jobArgs)
        {
            var storage = _dbContext.Set<TempStorage.TempStorage>()
                                    .Add(new TempStorage.TempStorage(JsonConvert.SerializeObject(jobArgs)));
            
            _dbContext.SaveChanges();

            return storage.Id;
        }

        public async Task<T> GetAsync<T>(long storageId)
        {
            var storage = await _dbContext.Set<TempStorage.TempStorage>().SingleOrDefaultAsync(_ => _.Id == storageId);
            if(storage == null) throw new ArgumentException("storageId not found");
            return JsonConvert.DeserializeObject<T>(storage.Value);
        }

        public T Get<T>(long storageId)
        {
            var storage = _dbContext.Set<TempStorage.TempStorage>().SingleOrDefault(_ => _.Id == storageId);
            if(storage == null) throw new ArgumentException("storageId not found");
            return JsonConvert.DeserializeObject<T>(storage.Value);
        }

        public async Task UpdateAsync<T>(long storageId, T jobArgs)
        {
            var storage = await _dbContext.Set<TempStorage.TempStorage>()
                                          .SingleAsync(_ => _.Id == storageId);

            storage.Value = JsonConvert.SerializeObject(jobArgs);

            await _dbContext.SaveChangesAsync();
        }

        public async Task CleanUpTempStorage(long storageId)
        {
            await _dbContext.Set<TempStorage.TempStorage>()
                                          .Where(_ => _.Id == storageId).DeleteAsync();
        }
    }
}
