using System;
using System.Linq;
using System.Threading.Tasks;
using Autofac;
using Dependable;
using Dependable.Dispatcher;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Names.Consolidations;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Names.Consolidation;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Names.Consolidations
{
    [Collection("Dependable")]
    public class NameConsolidationJobScenariosFacts : FactBase
    {
        [Fact]
        public async Task ShouldConsolidateMultipleNames()
        {
            var jobExecutionId = Fixture.Long();
            var nameToBeConsolidated1 = Fixture.Integer();
            var nameToBeConsolidated2 = Fixture.Integer();
            var nameToBeConsolidated3 = Fixture.Integer();
            var nameConsolidationArgs = new NameConsolidationArgs
            {
                ExecuteAs = Fixture.Integer(),
                NameIds = new[]
                {
                    nameToBeConsolidated1, nameToBeConsolidated2, nameToBeConsolidated3
                },
                TargetId = Fixture.Integer(),
                KeepTelecomHistory = Fixture.Boolean(),
                KeepAddressHistory = Fixture.Boolean(),
                KeepConsolidatedName = Fixture.Boolean()
            };

            var f = new NameConsolidationDependableWireup(Db);

            var nameConsolidationStatus = new NameConsolidationStatus();
            f.PersistJobState.Load<NameConsolidationStatus>(jobExecutionId).Returns(nameConsolidationStatus);

            var workflow = await f.Subject.ConsolidateNames(jobExecutionId, nameConsolidationArgs);

            f.Execute(workflow);

            f.SingleNameConsolidation
             .Received(1)
             .Consolidate(nameConsolidationArgs.ExecuteAs,
                          nameToBeConsolidated1,
                          nameConsolidationArgs.TargetId,
                          nameConsolidationArgs.KeepAddressHistory,
                          nameConsolidationArgs.KeepTelecomHistory,
                          nameConsolidationArgs.KeepConsolidatedName)
             .IgnoreAwaitForNSubstituteAssertion();

            f.SingleNameConsolidation
             .Received(1)
             .Consolidate(nameConsolidationArgs.ExecuteAs,
                          nameToBeConsolidated2,
                          nameConsolidationArgs.TargetId,
                          nameConsolidationArgs.KeepAddressHistory,
                          nameConsolidationArgs.KeepTelecomHistory,
                          nameConsolidationArgs.KeepConsolidatedName)
             .IgnoreAwaitForNSubstituteAssertion();

            f.SingleNameConsolidation
             .Received(1)
             .Consolidate(nameConsolidationArgs.ExecuteAs,
                          nameToBeConsolidated3,
                          nameConsolidationArgs.TargetId,
                          nameConsolidationArgs.KeepAddressHistory,
                          nameConsolidationArgs.KeepTelecomHistory,
                          nameConsolidationArgs.KeepConsolidatedName)
             .IgnoreAwaitForNSubstituteAssertion();

            f.PersistJobState
             .Received()
             .Save(jobExecutionId, nameConsolidationStatus)
             .IgnoreAwaitForNSubstituteAssertion();

            Assert.Contains(nameToBeConsolidated1, nameConsolidationStatus.NamesConsolidated);
            Assert.Contains(nameToBeConsolidated2, nameConsolidationStatus.NamesConsolidated);
            Assert.Contains(nameToBeConsolidated3, nameConsolidationStatus.NamesConsolidated);
            Assert.True(nameConsolidationStatus.IsCompleted);
            Assert.Empty(nameConsolidationStatus.Errors);
        }

        [Fact]
        public async Task ShouldConsolidateSingleName()
        {
            var jobExecutionId = Fixture.Long();
            var nameToBeConsolidated = Fixture.Integer();
            var nameConsolidationArgs = new NameConsolidationArgs
            {
                ExecuteAs = Fixture.Integer(),
                NameIds = new[]
                {
                    nameToBeConsolidated
                },
                TargetId = Fixture.Integer(),
                KeepTelecomHistory = Fixture.Boolean(),
                KeepAddressHistory = Fixture.Boolean(),
                KeepConsolidatedName = Fixture.Boolean()
            };

            var f = new NameConsolidationDependableWireup(Db);

            var nameConsolidationStatus = new NameConsolidationStatus();
            f.PersistJobState.Load<NameConsolidationStatus>(jobExecutionId).Returns(nameConsolidationStatus);

            var workflow = await f.Subject.ConsolidateNames(jobExecutionId, nameConsolidationArgs);

            f.Execute(workflow);

            f.SingleNameConsolidation
             .Received(1)
             .Consolidate(nameConsolidationArgs.ExecuteAs,
                          nameConsolidationArgs.NameIds.Single(),
                          nameConsolidationArgs.TargetId,
                          nameConsolidationArgs.KeepAddressHistory,
                          nameConsolidationArgs.KeepTelecomHistory,
                          nameConsolidationArgs.KeepConsolidatedName)
             .IgnoreAwaitForNSubstituteAssertion();

            f.PersistJobState
             .Received()
             .Save(jobExecutionId, nameConsolidationStatus)
             .IgnoreAwaitForNSubstituteAssertion();

            Assert.Contains(nameToBeConsolidated, nameConsolidationStatus.NamesConsolidated);
            Assert.True(nameConsolidationStatus.IsCompleted);
            Assert.Empty(nameConsolidationStatus.Errors);
        }

        [Fact]
        public async Task ShouldConsolidateAllNamesSkipOverFailedOnes()
        {
            var jobExecutionId = Fixture.Long();
            var nameToBeConsolidated1 = Fixture.Integer();
            var nameToBeConsolidated2 = Fixture.Integer();
            var nameToBeConsolidated3 = Fixture.Integer();
            var nameConsolidationArgs = new NameConsolidationArgs
            {
                ExecuteAs = Fixture.Integer(),
                NameIds = new[]
                {
                    nameToBeConsolidated1, nameToBeConsolidated2, nameToBeConsolidated3
                },
                TargetId = Fixture.Integer(),
                KeepTelecomHistory = Fixture.Boolean(),
                KeepAddressHistory = Fixture.Boolean(),
                KeepConsolidatedName = Fixture.Boolean()
            };

            var f = new NameConsolidationDependableWireup(Db);

            var nameConsolidationStatus = new NameConsolidationStatus();
            f.PersistJobState.Load<NameConsolidationStatus>(jobExecutionId).Returns(nameConsolidationStatus);
            f.SingleNameConsolidation
             .When(x => x.Consolidate(Arg.Any<int>(), nameToBeConsolidated2, Arg.Any<int>(), Arg.Any<bool>(), Arg.Any<bool>(), Arg.Any<bool>()))
             .Do(_ => throw new Exception("bummer"));

            var workflow = await f.Subject.ConsolidateNames(jobExecutionId, nameConsolidationArgs);

            f.Execute(workflow);

            f.SingleNameConsolidation
             .Received()
             .Consolidate(nameConsolidationArgs.ExecuteAs,
                          nameToBeConsolidated1,
                          nameConsolidationArgs.TargetId,
                          nameConsolidationArgs.KeepAddressHistory,
                          nameConsolidationArgs.KeepTelecomHistory,
                          nameConsolidationArgs.KeepConsolidatedName)
             .IgnoreAwaitForNSubstituteAssertion();

            f.SingleNameConsolidation
             .Received()
             .Consolidate(nameConsolidationArgs.ExecuteAs,
                          nameToBeConsolidated2,
                          nameConsolidationArgs.TargetId,
                          nameConsolidationArgs.KeepAddressHistory,
                          nameConsolidationArgs.KeepTelecomHistory,
                          nameConsolidationArgs.KeepConsolidatedName)
             .IgnoreAwaitForNSubstituteAssertion();

            f.SingleNameConsolidation
             .Received()
             .Consolidate(nameConsolidationArgs.ExecuteAs,
                          nameToBeConsolidated3,
                          nameConsolidationArgs.TargetId,
                          nameConsolidationArgs.KeepAddressHistory,
                          nameConsolidationArgs.KeepTelecomHistory,
                          nameConsolidationArgs.KeepConsolidatedName)
             .IgnoreAwaitForNSubstituteAssertion();

            f.FailedConsolidatingName
             .Received()
             .NameNotConsolidated(Arg.Any<ExceptionContext>(), jobExecutionId, nameToBeConsolidated2);

            f.FailedConsolidatingName
             .DidNotReceive()
             .NameNotConsolidated(Arg.Any<ExceptionContext>(), jobExecutionId, Arg.Is<int>(_ => _ == nameToBeConsolidated1 || _ == nameToBeConsolidated3));

            f.PersistJobState
             .Received()
             .Save(jobExecutionId, nameConsolidationStatus)
             .IgnoreAwaitForNSubstituteAssertion();

            Assert.Contains(nameToBeConsolidated1, nameConsolidationStatus.NamesConsolidated);
            Assert.DoesNotContain(nameToBeConsolidated2, nameConsolidationStatus.NamesConsolidated);
            Assert.Contains(nameToBeConsolidated3, nameConsolidationStatus.NamesConsolidated);
            Assert.True(nameConsolidationStatus.IsCompleted);
        }
    }

    public class NameConsolidationDependableWireup : IFixture<NameConsolidationJob>
    {
        readonly InMemoryDbContext _db;

        public NameConsolidationDependableWireup(InMemoryDbContext db)
        {
            _db = db;
            PersistJobState = Substitute.For<IPersistJobState>();
            SingleNameConsolidation = Substitute.For<ISingleNameConsolidation>();
            FailedConsolidatingName = Substitute.For<IFailedConsolidatingName>();
            Subject = new NameConsolidationJob(PersistJobState);
        }

        public IPersistJobState PersistJobState { get; set; }

        public ISingleNameConsolidation SingleNameConsolidation { get; set; }

        public IFailedConsolidatingName FailedConsolidatingName { get; set; }

        public NameConsolidationJob Subject { get; }

        ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
        {
            var builder = new ContainerBuilder();
            builder.RegisterInstance(_db).As<IDbContext>();
            builder.RegisterInstance(PersistJobState).As<IPersistJobState>();
            builder.RegisterInstance(SingleNameConsolidation).As<ISingleNameConsolidation>();
            builder.RegisterInstance(FailedConsolidatingName).As<IFailedConsolidatingName>();
            builder.RegisterType<NameConsolidationJob>().AsSelf();
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