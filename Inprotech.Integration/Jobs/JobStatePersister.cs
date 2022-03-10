using System.Data.Entity;
using System.Threading.Tasks;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Integration.Jobs
{
    public class JobStatePersister : IPersistJobState
    {
        readonly IRepository _repository;

        public JobStatePersister(IRepository repository)
        {
            _repository = repository;
        }

        public async Task<T> Load<T>(long jobExecutionId) where T : class
        {
            var job = await _repository.Set<JobExecution>().Include(j => j.Job).SingleOrDefaultAsync(e => e.Id == jobExecutionId);

            return job?.State == null ? default(T) : JsonConvert.DeserializeObject<T>(job.State);
        }

        public async Task Save<T>(long jobExecutionId, T value) where T : class
        {
            var job = await _repository.Set<JobExecution>().Include(j => j.Job).SingleOrDefaultAsync(e => e.Id == jobExecutionId);
            if (job == null) return;
            job.State = JsonConvert.SerializeObject(value);
            await _repository.SaveChangesAsync();
        }
    }
}