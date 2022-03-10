using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public interface IConfigureBulkCaseUpdatesJob
    {
        void AddBulkCaseUpdateJob<T>(T jobArguments);
        Task StartNextJob();
    }

    public class ConfigureBulkCaseUpdatesJob : IConfigureBulkCaseUpdatesJob
    {
        readonly IRepository _repository;
        readonly IConfigureJob _configureJob;

        public ConfigureBulkCaseUpdatesJob(IRepository repository, IConfigureJob configureJob)
        {
            _repository = repository;
            _configureJob = configureJob;
        }

        public void AddBulkCaseUpdateJob<T>(T jobArguments)
        {
            if (_configureJob.TryCreateOneTimeJob(nameof(BulkCaseUpdatesJob), jobArguments)) return;
            _repository.Set<BulkCaseUpdatesSchedule>().Add(new BulkCaseUpdatesSchedule
            {
                JobArguments = JsonConvert.SerializeObject(jobArguments)
            });
            _repository.SaveChanges();
        }

        public async Task StartNextJob()
        {
            var jobToRun = _repository.Set<BulkCaseUpdatesSchedule>().OrderBy(_ => _.Id).FirstOrDefault();
            if (jobToRun != null)
            {
                var args = JsonConvert.DeserializeObject<BulkCaseUpdatesArgs>(jobToRun.JobArguments);
                if (_configureJob.TryCreateOneTimeJob(nameof(BulkCaseUpdatesJob), args))
                {
                    _repository.Set<BulkCaseUpdatesSchedule>().Remove(jobToRun);
                    await _repository.SaveChangesAsync();
                }   
            }
        }
    }
}
