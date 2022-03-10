using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.Jobs;
using Inprotech.IntegrationServer.Jobs;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Jobs
{
    public class PendingJobsInterrupterFacts : FactBase
    {
        [Theory]
        [InlineData(JobRecurrence.Hourly, 60)]
        [InlineData(JobRecurrence.EveryMinute, 1)]
        [InlineData(JobRecurrence.EveryFiveMinutes, 5)]
        [InlineData(JobRecurrence.EveryTenMinutes, 10)]
        [InlineData(JobRecurrence.EveryFifteenMinutes, 15)]
        [InlineData(JobRecurrence.EveryThirtyMinutes, 30)]
        public async Task ReSchedulesAccordingToJobRecurrence(JobRecurrence recurrence, int delayInMinutes)
        {
            var theJob = new Job {NextRun = Fixture.Monday, IsActive = true, Recurrence = recurrence}.In(Db);

            var now = Fixture.Monday + TimeSpan.FromMinutes(1);

            var fixture = new PendingJobsInterrupterFixture(Db).WithNow(now).WithJobRunnerReady();

            await fixture.Subject.Interrupt();

            fixture.JobRunner.Received(1).Run(theJob).IgnoreAwaitForNSubstituteAssertion();

            Assert.True(theJob.IsActive);
            Assert.Equal(now + TimeSpan.FromMinutes(delayInMinutes), theJob.NextRun);
        }

        [Fact]
        public async Task DeactivatesRunOnceJobs()
        {
            var theJob = new Job {NextRun = Fixture.Monday, IsActive = true, Recurrence = JobRecurrence.Once}.In(Db);

            var now = Fixture.Monday + TimeSpan.FromMinutes(1);

            var fixture = new PendingJobsInterrupterFixture(Db).WithNow(now).WithJobRunnerReady();

            await fixture.Subject.Interrupt();

            fixture.JobRunner.Received(1).Run(theJob).IgnoreAwaitForNSubstituteAssertion();

            Assert.False(theJob.IsActive);
        }

        [Fact]
        public async Task RunsDueOrOverdueJobs()
        {
            var due = new Job {NextRun = Fixture.Monday, IsActive = true}.In(Db);
            var overdue = new Job {NextRun = Fixture.Monday - TimeSpan.FromMinutes(1), IsActive = true}.In(Db);
            var notDue = new Job {NextRun = Fixture.Tuesday, IsActive = true}.In(Db);

            var now = Fixture.Monday;

            var fixture =
                new PendingJobsInterrupterFixture(Db).WithNow(now).WithJobRunnerReady();

            await fixture.Subject.Interrupt();

            fixture.JobRunner.Received(1).Run(due).IgnoreAwaitForNSubstituteAssertion();
            fixture.JobRunner.Received(1).Run(overdue).IgnoreAwaitForNSubstituteAssertion();
            fixture.JobRunner.DidNotReceive().Run(notDue).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task RunsJobsCorrespondingToCurrentInstanceName()
        {
            var currentInstanceJob = new Job {NextRun = Fixture.Monday, IsActive = true, RunOnInstanceName = "Jack"}.In(Db);
            var otherInstanceJob = new Job {NextRun = Fixture.Monday, IsActive = true, RunOnInstanceName = "Jill"}.In(Db);

            var now = Fixture.Monday;

            var fixture = new PendingJobsInterrupterFixture(Db).WithNow(now).WithJobRunnerReady();
            fixture.AppSettingsProvider["InstanceName"].Returns("Jack");

            await fixture.Subject.Interrupt();

            fixture.JobRunner.Received(1).Run(currentInstanceJob).IgnoreAwaitForNSubstituteAssertion();
            fixture.JobRunner.DidNotReceive().Run(otherInstanceJob).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldNotRunIfJobRunnerIsNotReady()
        {
            new Job {NextRun = Fixture.Monday, IsActive = true, RunOnInstanceName = "Jill"}.In(Db);

            var now = Fixture.Monday;

            var fixture = new PendingJobsInterrupterFixture(Db).WithNow(now);
            
            await fixture.Subject.Interrupt();

            fixture.JobRunner.DidNotReceive().Run(Arg.Any<Job>()).IgnoreAwaitForNSubstituteAssertion();
        }
    }

    public class PendingJobsInterrupterFixture : IFixture<PendingJobsInterrupter>
    {
        readonly InMemoryDbContext _db;

        public PendingJobsInterrupterFixture(InMemoryDbContext db)
        {
            _db = db;
            Now = DateTime.Now;
            JobRunner = Substitute.For<IJobRunner>();
            AppSettingsProvider = Substitute.For<IAppSettingsProvider>();
        }

        public DateTime Now { get; private set; }

        public IAppSettingsProvider AppSettingsProvider { get; set; }

        public IJobRunner JobRunner { get; set; }

        public PendingJobsInterrupter Subject
        {
            get
            {
                return new PendingJobsInterrupter(
                                                  _db,
                                                  JobRunner,
                                                  () => Now, AppSettingsProvider);
            }
        }

        public PendingJobsInterrupterFixture WithNow(DateTime now)
        {
            Now = now;
            return this;
        }

        public PendingJobsInterrupterFixture WithJobRunnerReady()
        {
            JobRunner.IsReady.Returns(true);
            return this;
        }
    }
}