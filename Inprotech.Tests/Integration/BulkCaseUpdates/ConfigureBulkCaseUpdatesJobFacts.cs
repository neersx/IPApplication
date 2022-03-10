using Inprotech.Integration.BulkCaseUpdates;
using Inprotech.Integration.Jobs;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using NSubstitute;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Integration.BulkCaseUpdates
{
    public class ConfigureBulkCaseUpdatesJobFacts : FactBase
    {
        [Fact]
        public void DirectlyRunsJobWhenNoOtherJobRunning()
        {
            var f = new ConfigureBulkCaseUpdatesJobFixture(Db);
            f.ConfigureJob.TryCreateOneTimeJob(nameof(BulkCaseUpdatesJob), Arg.Any<BulkCaseUpdatesArgs>()).Returns(true);
            var args = new BulkCaseUpdatesArgs {ProcessId = Fixture.Integer(), CaseIds = new[] {Fixture.Integer()}};
            f.Subject.AddBulkCaseUpdateJob(args);
            Assert.Empty(Db.Set<BulkCaseUpdatesSchedule>());
        }

        [Fact]
        public void ShouldAddBulkCaseUpdateJobWhenAnotherJobRunning()
        {
            var f = new ConfigureBulkCaseUpdatesJobFixture(Db);
            f.ConfigureJob.TryCreateOneTimeJob(nameof(BulkCaseUpdatesJob), Arg.Any<BulkCaseUpdatesArgs>()).Returns(false);
            var args = new BulkCaseUpdatesArgs {ProcessId = Fixture.Integer(), CaseIds = new[] {Fixture.Integer()}};
            f.Subject.AddBulkCaseUpdateJob(args);
            var jobs = Db.Set<BulkCaseUpdatesSchedule>();
            Assert.NotNull(jobs);
            Assert.Equal(1, jobs.Count());
        }

        [Fact]
        public async Task ShouldStartNextJobWhenExists()
        {
            var f = new ConfigureBulkCaseUpdatesJobFixture(Db);
            var args = new BulkCaseUpdatesArgs {ProcessId = Fixture.Integer(), CaseIds = new[] {Fixture.Integer()}};
            new BulkCaseUpdatesSchedule {JobArguments = JsonConvert.SerializeObject(args)}.In(Db);
            f.ConfigureJob.TryCreateOneTimeJob(nameof(BulkCaseUpdatesJob), Arg.Any<BulkCaseUpdatesArgs>()).Returns(true);
            await f.Subject.StartNextJob();
            f.ConfigureJob.Received(1).TryCreateOneTimeJob(nameof(BulkCaseUpdatesJob), Arg.Any<BulkCaseUpdatesArgs>());
            Assert.Empty(Db.Set<BulkCaseUpdatesSchedule>());
        }

        [Fact]
        public async Task ShouldNotStartNextJobWhenNotExists()
        {
            var f = new ConfigureBulkCaseUpdatesJobFixture(Db);
            f.ConfigureJob.TryCreateOneTimeJob(nameof(BulkCaseUpdatesJob), Arg.Any<string>()).Returns(true);
            await f.Subject.StartNextJob();
            f.ConfigureJob.DidNotReceive().TryCreateOneTimeJob(nameof(BulkCaseUpdatesJob), Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldNotRemoveScheduleIfFailedToRunJob()
        {
            var f = new ConfigureBulkCaseUpdatesJobFixture(Db);
            var args = new BulkCaseUpdatesArgs {ProcessId = Fixture.Integer(), CaseIds = new[] {Fixture.Integer()}};
            new BulkCaseUpdatesSchedule {JobArguments = JsonConvert.SerializeObject(args)}.In(Db);
            f.ConfigureJob.TryCreateOneTimeJob(nameof(BulkCaseUpdatesJob), Arg.Any<BulkCaseUpdatesArgs>()).Returns(false);
            await f.Subject.StartNextJob();
            f.ConfigureJob.Received(1).TryCreateOneTimeJob(nameof(BulkCaseUpdatesJob), Arg.Any<BulkCaseUpdatesArgs>());
            Assert.Equal(1, Db.Set<BulkCaseUpdatesSchedule>().Count());
        }
    }

    public class ConfigureBulkCaseUpdatesJobFixture : IFixture<ConfigureBulkCaseUpdatesJob>
    {
        public ConfigureBulkCaseUpdatesJobFixture(InMemoryDbContext db)
        {
            ConfigureJob = Substitute.For<IConfigureJob>();

            Subject = new ConfigureBulkCaseUpdatesJob(db, ConfigureJob);
        }

        public IConfigureJob ConfigureJob { get; }
        public ConfigureBulkCaseUpdatesJob Subject { get; }
    }
}
