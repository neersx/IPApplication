using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Jobs.States;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Jobs
{
    public class JobStatus
    {
        public bool HasErrors;
        public bool IsActive;

        public JObject JobArguments;

        public long? JobExecutionId;

        public long? JobId;

        public JObject State;

        public string Status;
    }

    public interface IConfigureJob
    {
        void StartJob(string jobType);

        bool TryCreateOneTimeJob<T>(string jobType, T jobArguments);

        JobStatus GetJobStatus(string jobType);

        Task Acknowledge(long jobExecutionId);
    }

    public class ConfigureJob : IConfigureJob
    {
        readonly Func<DateTime> _now;
        readonly IPersistJobState _persister;
        readonly IRepository _repository;

        public ConfigureJob(IRepository repository, Func<DateTime> now, IPersistJobState persister)
        {
            _repository = repository;
            _now = now;
            _persister = persister;
        }

        public void StartJob(string jobType)
        {
            var job = _repository.Set<Job>().Single(j => j.Type == jobType);

            ScheduleJob(job);

            _repository.SaveChanges();
        }

        public bool TryCreateOneTimeJob<T>(string jobType, T jobArguments)
        {
            var now = _now();

            if (_repository.Set<Job>().Any(j => j.Type == jobType && j.IsActive))
            {
                return false;
            }

            _repository.Set<Job>().Add(new Job
            {
                IsActive = true,
                NextRun = now,
                JobArguments = JsonConvert.SerializeObject(jobArguments),
                Recurrence = JobRecurrence.Once,
                Type = jobType
            });

            _repository.SaveChanges();

            return true;
        }

        public JobStatus GetJobStatus(string jobType)
        {
            return AllJobStatus(jobType, 1).SingleOrDefault() ?? new JobStatus();
        }

        public async Task Acknowledge(long jobExecutionId)
        {
            var state = await _persister.Load<SendAllDocumentsForSourceState>(jobExecutionId);
            state.Acknowledged = true;
            await _persister.Save(jobExecutionId, state);
        }

        void ScheduleJob(Job job)
        {
            job.IsActive = true;
            job.NextRun = _now();
        }

        IEnumerable<JobStatus> AllJobStatus(string jobType, int top)
        {
            var interim = (from jobExecution in _repository.Set<JobExecution>()
                           join job in _repository.Set<Job>() on jobExecution.JobId equals job.Id
                           where job.Type == jobType && jobExecution.Started >= job.NextRun
                           group jobExecution by jobExecution.Job
                           into g1
                           select new InterimJobStatus
                           {
                               JobId = g1.Key.Id,
                               IsActive = g1.Key.IsActive,
                               JobArguments = g1.Key.JobArguments,
                               JobExecution = g1.DefaultIfEmpty().OrderByDescending(_ => _.Started).FirstOrDefault()
                           })
                          .Union(from job in _repository.Set<Job>()
                                 join jobExecution in _repository.Set<JobExecution>() on job.Id equals jobExecution.JobId into je2
                                 from jobExecution in je2.DefaultIfEmpty()
                                 where jobExecution == null && job.Type == jobType
                                 select new InterimJobStatus
                                 {
                                     JobId = job.Id,
                                     IsActive = job.IsActive,
                                     JobArguments = job.JobArguments,
                                     JobExecution = null
                                 })
                          /* in job submission order, and picking most recent execution for that job */
                          .OrderByDescending(_ => _.JobId)
                          .Take(top)
                          .ToArray();

            return interim.Select(_ => new JobStatus
            {
                JobId = _.JobId,
                JobExecutionId = _.JobExecution?.Id,
                JobArguments = string.IsNullOrWhiteSpace(_.JobArguments) ? null : JObject.Parse(_.JobArguments),
                IsActive = _.IsActive,
                State = string.IsNullOrWhiteSpace(_.JobExecution?.State) ? new JObject() : JObject.Parse(_.JobExecution.State),
                Status = _.JobExecution?.Status.ToString(),
                HasErrors = !string.IsNullOrWhiteSpace(_.JobExecution?.Error)
            });
        }

        class InterimJobStatus
        {
            public bool IsActive;

            public string JobArguments;

            public JobExecution JobExecution;

            public long? JobId;
        }
    }
}