using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.IntegrationServer.BackgroundProcessing;

namespace Inprotech.IntegrationServer.Jobs
{
    public class PendingJobsInterrupter : IInterrupter
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly IJobRunner _jobRunner;
        readonly Func<DateTime> _now;
        readonly IRepository _repository;

        public PendingJobsInterrupter(IRepository repository, IJobRunner jobRunner, Func<DateTime> now, IAppSettingsProvider appSettingsProvider)
        {
            _repository = repository;
            _jobRunner = jobRunner;
            _now = now;
            _appSettingsProvider = appSettingsProvider;
        }

        public async Task Interrupt()
        {
            if (!_jobRunner.IsReady) return;

            var currentInstance = _appSettingsProvider["InstanceName"];

            var jobs = await _repository.Set<Job>()
                                        .Where(_ => _.IsActive && (_.RunOnInstanceName == null || _.RunOnInstanceName == currentInstance))
                                        .ToListAsync();

            var now = _now();

            foreach (var job in jobs.Where(j => ShouldExecute(now, j)))
            {
                var recurrenceDelay = (int) job.Recurrence;

                if (job.Recurrence == JobRecurrence.Once)
                {
                    job.IsActive = false;
                }
                else
                {
                    job.NextRun = now.AddMinutes(recurrenceDelay);
                }

                await _repository.SaveChangesAsync();

                await _jobRunner.Run(job);
            }
        }

        static bool ShouldExecute(DateTime now, Job job)
        {
            return now >= job.NextRun;
        }
    }
}