using Autofac;
using Dependable;
using Inprotech.Integration.BulkCaseUpdates;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Jobs;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Integration.BulkCaseUpdates
{
    [Collection("Dependable")]
    public class BulkCaseUpdatesJobFacts : FactBase
    {
        [Fact]
        public async Task ShouldCallBulkFieldUpdates()
        {
            var jobExecutionId = Fixture.Long();
            var bulkCaseUpdatesArgs = new BulkCaseUpdatesArgs()
            {
                CaseIds = new[] {Fixture.Integer(), Fixture.Integer(), Fixture.Integer()},
                ProcessId = Fixture.Short(),
                SaveData = new BulkUpdateData
                {
                    CaseFamily = new BulkSaveData {Key = Fixture.String("F")},
                    EntitySize = new BulkSaveData {Key = Fixture.Integer().ToString()}
                }
            };

            var f = new BulkCaseUpdateDependableWireUp(Db);
            var status = new BulkCaseUpdatesStatus();
            f.PersistJobState.Load<BulkCaseUpdatesStatus>(jobExecutionId).Returns(status);
            var workflow = await f.Subject.BulkUpdate(jobExecutionId, bulkCaseUpdatesArgs);
            f.Execute(workflow);

            f.BulkFieldUpdates.Received(1).BulkUpdateCases(bulkCaseUpdatesArgs)
             .IgnoreAwaitForNSubstituteAssertion();
            
            f.PersistJobState
             .Received()
             .Save(jobExecutionId, status)
             .IgnoreAwaitForNSubstituteAssertion();

            f.ConfigureJob.Received(1).StartNextJob()
             .IgnoreAwaitForNSubstituteAssertion();

            Assert.True(status.IsCompleted);
        }

    }

    public class BulkCaseUpdateDependableWireUp : IFixture<BulkCaseUpdatesJob>
    {
        readonly InMemoryDbContext _db;

        public BulkCaseUpdateDependableWireUp(InMemoryDbContext db)
        {
            _db = db;
            PersistJobState = Substitute.For<IPersistJobState>();
            BulkFieldUpdates = Substitute.For<IBulkFieldUpdates>();
            ConfigureJob = Substitute.For<IConfigureBulkCaseUpdatesJob>();
            Subject = new BulkCaseUpdatesJob(PersistJobState);
        }

        public IPersistJobState PersistJobState { get; set; }
        public IConfigureBulkCaseUpdatesJob ConfigureJob { get; set; }

        public IBulkFieldUpdates BulkFieldUpdates { get; set; }

        public BulkCaseUpdatesJob Subject { get; }

        ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
        {
            var builder = new ContainerBuilder();
            builder.RegisterInstance(_db).As<IDbContext>();
            builder.RegisterInstance(PersistJobState).As<IPersistJobState>();
            builder.RegisterInstance(BulkFieldUpdates).As<IBulkFieldUpdates>();
            builder.RegisterInstance(ConfigureJob).As<IConfigureBulkCaseUpdatesJob>();
            builder.RegisterType<BulkCaseUpdatesJob>().AsSelf();
            builder.RegisterType<NullActivity>().AsSelf();
            builder.RegisterInstance(completedActivity).AsSelf();
            return builder.Build();
        }

        public void Execute(Activity activity)
        {
            DependableActivity.Execute(activity, WireUp);
        }
    }
}
