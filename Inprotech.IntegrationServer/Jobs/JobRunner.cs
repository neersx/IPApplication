using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;
using Job = Inprotech.Integration.Jobs.Job;

namespace Inprotech.IntegrationServer.Jobs
{
    public interface IJobRunner
    {
        Task Run(Job job);

        bool IsReady { get; }
    }

    public class JobRunner : IJobRunner
    {
        readonly IManageJobExecutionStatus _jobExecutionStatusUpdater;

        readonly Dictionary<string, Func<long, JObject, SingleActivity>> _jobs;

        public JobRunner(IEnumerable<IPerformBackgroundJob> jobs, IManageJobExecutionStatus jobExecutionStatusUpdater)
        {
            _jobExecutionStatusUpdater = jobExecutionStatusUpdater;
            _jobs = jobs.ToDictionary<IPerformBackgroundJob, string, Func<long, JObject, SingleActivity>>(j => j.Type, k => (id, args) => k.GetJob(id, args));
        }

        public bool IsReady => Configuration.Scheduler != null;

        public async Task Run(Job job)
        {
            if (job == null) throw new ArgumentNullException(nameof(job));

            var jobExecution = await _jobExecutionStatusUpdater.CreateJobExecution(job);

            try
            {

                if (!_jobs.TryGetValue(job.Type, out Func<long, JObject, SingleActivity> jobWorkflowBuilder))
                {
                    await _jobExecutionStatusUpdater.JobFailedToStart($"Job type '{job.Type}' is not registered in container", jobExecution.Id);
                    return;
                }

                var jobWorkflow = jobWorkflowBuilder(jobExecution.Id, string.IsNullOrEmpty(job.JobArguments) ? null : JObject.Parse(job.JobArguments));

                var entireJobWorkflow = Activity.Sequence(
                                                          jobWorkflow,
                                                          Activity.Run<IManageJobExecutionStatus>(u => u.JobCompleted(jobExecution.Id))
                                                         )
                                                .ExceptionFilter<IManageJobExecutionStatus>((e, u) => u.JobFailed(e, jobExecution.Id));

                await _jobExecutionStatusUpdater.JobStarted(jobExecution.Id);

                Configuration.Scheduler.Schedule(entireJobWorkflow);
            }
            catch (Exception e)
            {
                await _jobExecutionStatusUpdater.JobFailedToStart(e.Message, jobExecution.Id);
            }
        }
    }
}