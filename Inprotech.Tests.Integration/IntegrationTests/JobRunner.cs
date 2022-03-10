using System;
using System.Linq;
using System.Threading;
using Inprotech.Integration.Jobs;
using Inprotech.Tests.Integration.DbHelpers;
using Newtonsoft.Json;

namespace Inprotech.Tests.Integration.IntegrationTests
{
    public class JobRunner
    {
        public static void RunUntilComplete<T>(string jobType, T args)
        {
            var jobId = IntegrationDbSetup.Do(x => x.Insert(new Job
            {
                Type = jobType,
                NextRun = DateTime.Now,
                IsActive = true,
                JobArguments = JsonConvert.SerializeObject(args)
            }).Id);

            while (true)
            {
                var done = IntegrationDbSetup.Do(x => x.IntegrationDbContext.Set<JobExecution>().Any(_ => _.JobId == jobId && _.Finished != null));

                if (done) break;

                Thread.Sleep(TimeSpan.FromSeconds(3));
            }
        }
    }
}