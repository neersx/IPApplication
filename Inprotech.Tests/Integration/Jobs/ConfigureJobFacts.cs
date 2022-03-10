using System;
using System.Threading.Tasks;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Jobs.States;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Jobs
{
    public class ConfigureJobFacts : FactBase
    {
        [Fact]
        public async Task ShouldAcknowledgeJobStatus()
        {
            var fixture = new ConfigureJobFixture(Db);

            await fixture.Subject.Acknowledge(1);

            fixture.JobStatePersister.Received(1).Load<SendAllDocumentsForSourceState>(1)
                   .IgnoreAwaitForNSubstituteAssertion();

            fixture.JobStatePersister.Received(1).Save(1, Arg.Is<SendAllDocumentsForSourceState>(_ => _.Acknowledged))
                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void ShouldGetNormalJobStatusWithJobExecution()
        {
            var job = new Job
            {
                Type = "a",
                NextRun = DateTime.Now.AddMinutes(-1)
            }.In(Db);

            var je = new JobExecution
            {
                Job = job,
                JobId = job.Id,
                Status = Status.Started,
                State = "{\"a\":\"b\"}",
                Error = "e",
                Started = DateTime.Now
            }.In(Db);

            var r = new ConfigureJobFixture(Db).Subject.GetJobStatus("a");

            Assert.Equal("Started", r.Status);
            Assert.Equal(JObject.Parse("{\"a\":\"b\"}"), r.State);
            Assert.True(r.HasErrors);
            Assert.Equal(je.Id, r.JobExecutionId);
        }

        [Fact]
        public void ShouldGetParameterisedJobStatusWithJobExecution()
        {
            var job1 = new Job
            {
                Type = "a",
                NextRun = DateTime.Now.AddMinutes(-10)
            }.In(Db);

            var job2 = new Job
            {
                Type = "a",
                NextRun = DateTime.Now.AddMinutes(-1)
            }.In(Db);

            var je1 = new JobExecution
            {
                Job = job1,
                JobId = job1.Id,
                Status = Status.Started,
                State = "{\"a\":\"c\"}",
                Error = "e",
                Started = DateTime.Now
            }.In(Db);

            var je2 = new JobExecution
            {
                Job = job2,
                JobId = job2.Id,
                Status = Status.Started,
                State = "{\"a\":\"b\"}",
                Error = "e",
                Started = DateTime.Now
            }.In(Db);

            var r = new ConfigureJobFixture(Db).Subject.GetJobStatus("a");

            Assert.Equal("Started", r.Status);
            Assert.Equal(JObject.Parse("{\"a\":\"b\"}"), r.State);
            Assert.True(r.HasErrors);
            Assert.Equal(je2.Id, r.JobExecutionId);
        }

        [Fact]
        public void ShouldGetNormalJobStatusWithNoJobExecution()
        {
            new Job
            {
                IsActive = true,
                Type = "a"
            }.In(Db);

            var r = new ConfigureJobFixture(Db).Subject.GetJobStatus("a");

            Assert.True(r.IsActive);
            Assert.Null(r.Status);
        }

        [Fact]
        public void ShouldGetJobStatusFromMostRecentlySubmittedParameterisedJobWithNoJobExecution()
        {
            new Job
            {
                IsActive = false,
                Type = "a"
            }.In(Db);
            
            new Job
            {
                IsActive = true,
                Type = "a"
            }.In(Db);

            var r = new ConfigureJobFixture(Db).Subject.GetJobStatus("a");

            Assert.True(r.IsActive);
            Assert.Null(r.Status);
        }

        [Fact]
        public void ShouldGetLastRunJobExecution()
        {
            var job = new Job
            {
                Type = "a",
                NextRun = DateTime.Now.AddMinutes(-2)
            }.In(Db);

            var je = new JobExecution
            {
                Job = job,
                JobId = job.Id,
                Started = DateTime.Now
            }.In(Db);

            new JobExecution
            {
                Job = job,
                JobId = job.Id,
                Started = DateTime.Now.AddMinutes(-1)
            }.In(Db);

            var r = new ConfigureJobFixture(Db).Subject.GetJobStatus("a");

            Assert.Equal(je.Id, r.JobExecutionId);
        }

        [Fact]
        public void ShouldStartJob()
        {
            var job = new Job
            {
                Type = "a"
            }.In(Db);

            new ConfigureJobFixture(Db).Subject.StartJob("a");

            Assert.True(job.IsActive);
            Assert.Equal(Fixture.Today(), job.NextRun);
        }
    }

    public class ConfigureJobFixture : IFixture<ConfigureJob>
    {
        public ConfigureJobFixture(InMemoryDbContext db)
        {
            JobStatePersister = Substitute.For<IPersistJobState>();
            JobStatePersister.Load<SendAllDocumentsForSourceState>(0)
                             .ReturnsForAnyArgs(new SendAllDocumentsForSourceState());

            Subject = new ConfigureJob(db, Fixture.Today, JobStatePersister);
        }

        public IPersistJobState JobStatePersister { get; }
        public ConfigureJob Subject { get; }
    }
}