using System.Linq;
using System.Threading.Tasks;
using Dependable.Dispatcher;
using Inprotech.Integration.Jobs;
using Inprotech.IntegrationServer.Jobs;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Jobs
{
    public class JobStatusUpdaterFacts
    {
        public class JobFailedMethod : FactBase
        {
            [Fact]
            public async Task AddsToExistingExceptions()
            {
                var f = new JobStatusUpdaterFixture(Db);
                new JobExecution {Id = 123456, Error = "[{ Method: 'ExistingError' }]"}.In(Db);

                await f.Subject.JobFailed(new ExceptionContext {Method = "NewError"}, 123456);
                var je = Db.Set<JobExecution>().Single(j => j.Id == 123456);

                Assert.Contains("ExistingError", je.Error);
                Assert.Contains("NewError", je.Error);
            }

            [Fact]
            public async Task RegistersNewException()
            {
                var f = new JobStatusUpdaterFixture(Db);
                new JobExecution {Id = 123456}.In(Db);

                await f.Subject.JobFailed(new ExceptionContext {Method = "MyClass.Method"}, 123456);
                var je = Db.Set<JobExecution>().Single(j => j.Id == 123456);

                Assert.Contains("MyClass.Method", je.Error);
            }
        }

        public class JobCompletedMethod : FactBase
        {
            [Fact]
            public async Task ShouldCompleteJob()
            {
                var f = new JobStatusUpdaterFixture(Db);
                new JobExecution {Id = 123456, JobId = 1, Job = new Job {Id = 1}, Status = Status.Started}.In(Db);
                await f.Subject.JobCompleted(123456);
                var je = Db.Set<JobExecution>().Single(j => j.Id == 123456);

                Assert.Equal(Fixture.Today(), je.Finished);
                Assert.Equal(Status.Completed, je.Status);
            }
        }

        public class JobFailedToStartMethod : FactBase
        {
            [Fact]
            public async Task ShouldSetErrorToCorrectValue()
            {
                var f = new JobStatusUpdaterFixture(Db);
                new JobExecution {Id = 123456, JobId = 1, Job = new Job {Id = 1}, Status = Status.Started}.In(Db);
                await f.Subject.JobFailedToStart("error message", 123456);
                var je = Db.Set<JobExecution>().Single(j => j.Id == 123456);
                Assert.Equal("error message", je.Error);
            }

            [Fact]
            public async Task ShouldSetStatusToFailed()
            {
                var f = new JobStatusUpdaterFixture(Db);
                new JobExecution {Id = 123456, JobId = 1, Job = new Job {Id = 1}, Status = Status.Started}.In(Db);
                await f.Subject.JobFailedToStart("error message", 123456);
                var je = Db.Set<JobExecution>().Single(j => j.Id == 123456);
                Assert.Equal(Status.Failed, je.Status);
            }
        }

        public class JobStartedMethod : FactBase
        {
            [Fact]
            public async Task ShouldSetStartedToCorrectValue()
            {
                var f = new JobStatusUpdaterFixture(Db);
                new JobExecution {Id = 123456, JobId = 1, Job = new Job {Id = 1}, Status = Status.None}.In(Db);
                await f.Subject.JobStarted(123456);
                var je = Db.Set<JobExecution>().Single(j => j.Id == 123456);
                Assert.Equal(Fixture.Today(), je.Started);
            }

            [Fact]
            public async Task ShouldSetStatusToStarted()
            {
                var f = new JobStatusUpdaterFixture(Db);
                new JobExecution {Id = 123456, JobId = 1, Job = new Job {Id = 1}, Status = Status.None}.In(Db);
                await f.Subject.JobStarted(123456);
                var je = Db.Set<JobExecution>().Single(j => j.Id == 123456);
                Assert.Equal(Status.Started, je.Status);
            }
        }

        public class CreateJobExecutionMethod : FactBase
        {
            [Fact]
            public async Task ShouldCreateJobExecutionWithCorrectJob()
            {
                var f = new JobStatusUpdaterFixture(Db);
                var je = await f.Subject.CreateJobExecution(new Job {Id = 1});
                Assert.Equal(1, je.Job.Id);
            }

            [Fact]
            public async Task ShouldCreateJobExecutionWithStartedDateNull()
            {
                var f = new JobStatusUpdaterFixture(Db);
                var je = await f.Subject.CreateJobExecution(new Job {Id = 1});
                Assert.False(je.Started.HasValue);
            }

            [Fact]
            public async Task ShouldCreateJobExecutionWithStatusNone()
            {
                var f = new JobStatusUpdaterFixture(Db);
                var je = await f.Subject.CreateJobExecution(new Job {Id = 1});
                Assert.Equal(Status.None, je.Status);
            }
        }
    }

    public class JobStatusUpdaterFixture : IFixture<JobExecutionStatusManager>
    {
        public JobStatusUpdaterFixture(InMemoryDbContext db)
        {
            Subject = new JobExecutionStatusManager(db, Fixture.Today);
        }

        public JobExecutionStatusManager Subject { get; }
    }
}