using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Dependable.Dispatcher;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;

#pragma warning disable 1998

namespace Inprotech.IntegrationServer.Jobs
{
    public interface IManageJobExecutionStatus
    {
        Task JobFailed(ExceptionContext ec, long jobExecutionId);
        Task JobStarted(long jobExecutionId);
        Task JobFailedToStart(string error, long jobExecutionId);
        Task JobCompleted(long jobExecutionId);
        Task<JobExecution> CreateJobExecution(Job job);
    }

    public class JobExecutionStatusManager : IManageJobExecutionStatus
    {
        readonly IRepository _repository;
        readonly Func<DateTime> _now;

        public JobExecutionStatusManager(IRepository repository, Func<DateTime> now)
        {
            _repository = repository;
            _now = now;
        }

        public async Task JobFailed(ExceptionContext ec, long jobExecutionId)
        {
            var jobExecution = await GetJobExecution(jobExecutionId);
            var errors = new List<ExceptionContext>();
            if (!string.IsNullOrWhiteSpace(jobExecution.Error))
                errors = new List<ExceptionContext>(JsonConvert.DeserializeObject<IEnumerable<ExceptionContext>>(jobExecution.Error));

            errors.Add(ec);
            jobExecution.Error = JsonConvert.SerializeObject(errors);
            jobExecution.Status = Status.Failed;
            await _repository.SaveChangesAsync();
        }

        public async Task<JobExecution> CreateJobExecution(Job job)
        {
            var jobExecution = _repository.Set<JobExecution>().Add(new JobExecution
            {
                Job = job,
                Started = null,
                Status = Status.None
            });

            await _repository.SaveChangesAsync();
            return jobExecution;
        }

        public async Task JobStarted(long jobExecutionId)
        {
            var jobExecution = await GetJobExecution(jobExecutionId);
            jobExecution.Status = Status.Started;
            jobExecution.Started = _now();
            await _repository.SaveChangesAsync();
        }

        async Task<JobExecution> GetJobExecution(long id)
        {
            return await GetJobExecution().SingleAsync(_ => _.Id == id);
        }

        IQueryable<JobExecution> GetJobExecution()
        {
            return _repository.Set<JobExecution>().Include(j => j.Job);
        }

        public async Task JobFailedToStart(string error, long jobExecutionId)
        {
            var jobExecution = GetJobExecution().Single(_ => _.Id == jobExecutionId);
            var job = jobExecution.Job;

            jobExecution.Status = Status.Failed;
            jobExecution.Error = error;

            if (!string.IsNullOrWhiteSpace(job.JobArguments) && job.Recurrence == JobRecurrence.Once)
                job.IsActive = false;

            await _repository.SaveChangesAsync();
        }

        public async Task JobCompleted(long jobExecutionId)
        {
            var jobExecution = await GetJobExecution(jobExecutionId);
            var job = jobExecution.Job;

            jobExecution.Finished = _now();
            jobExecution.Status = Status.Completed;

            if (!string.IsNullOrWhiteSpace(job.JobArguments) && job.Recurrence == JobRecurrence.Once)
                job.IsActive = false;

            await _repository.SaveChangesAsync();
        }
    }
}