using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Policing
{
    public class BatchPolicingRequestFacts
    {
        public class ShouldPoliceImmediatelyMethod : FactBase
        {
            [Theory]
            [InlineData(true, true)]
            [InlineData(false, true)]
            [InlineData(true, false)]
            [InlineData(false, false)]
            [InlineData(true, null)]
            [InlineData(false, null)]
            public void FavoursPolicingContinuously(bool policeImmediately, bool? otherPoliceImmediateConsiderations)
            {
                var f = new BatchPolicingRequestFixture(Db);
                f.PolicingUtility.IsPoliceImmediately().Returns(policeImmediately);
                new SiteControl(SiteControls.PoliceContinuously, true).In(Db);
                var result = f.Subject.ShouldPoliceImmediately(otherPoliceImmediateConsiderations);
                Assert.False(result);
            }

            [Theory]
            [InlineData(true, true, true)]
            [InlineData(false, true, true)]
            [InlineData(true, false, true)]
            [InlineData(false, false, false)]
            [InlineData(true, null, true)]
            [InlineData(false, null, false)]
            public void DefersPoliceImmediateToPolicingUtilityWhenNotPolicingContinuously(bool policeImmediately, bool? otherPoliceImmediateConsiderations, bool expected)
            {
                var f = new BatchPolicingRequestFixture(Db);
                f.PolicingUtility.IsPoliceImmediately().Returns(policeImmediately);
                new SiteControl(SiteControls.PoliceContinuously, false).In(Db);
                var result = f.Subject.ShouldPoliceImmediately(otherPoliceImmediateConsiderations);
                Assert.Equal(expected, result);
            }
        }

        public class EnqueueMethod : FactBase
        {
            [Fact]
            public void CreatesPolicingBatchNoForPoliceImmediate()
            {
                var f = new BatchPolicingRequestFixture(Db);

                var q = new PoliceCaseEvent(new CaseEventBuilder().Build());

                var batchNo = Fixture.Integer();
                f.PolicingEngine.CreateBatch().ReturnsForAnyArgs(batchNo);
                f.PolicingUtility.IsPoliceImmediately().ReturnsForAnyArgs(true);

                var result = f.Subject.Enqueue(new[] {q});
                Assert.Equal(batchNo, result);
                f.PolicingEngine.Received(1).CreateBatch();
            }

            [Fact]
            public void DoesNotCreatePolicingBatchNoIfNotPoliceImmediate()
            {
                var f = new BatchPolicingRequestFixture(Db);
                var q = new PoliceCaseEvent(new CaseEventBuilder().Build());

                f.PolicingEngine.CreateBatch().ReturnsForAnyArgs(Fixture.Integer());
                f.PolicingUtility.IsPoliceImmediately().ReturnsForAnyArgs(false);

                var result = f.Subject.Enqueue(new[] {q});

                Assert.Null(result);
                f.PolicingEngine.DidNotReceive().CreateBatch();
            }

            [Fact]
            public void DoesNotCreatePolicingBatchNoIfPolicingContinuously()
            {
                var f = new BatchPolicingRequestFixture(Db);
                var q = new PoliceCaseEvent(new CaseEventBuilder().Build());

                f.PolicingEngine.CreateBatch().ReturnsForAnyArgs(Fixture.Integer());
                f.PolicingUtility.IsPoliceImmediately().ReturnsForAnyArgs(true);
                new SiteControl(SiteControls.PoliceContinuously, true).In(Db);

                var result = f.Subject.Enqueue(new[] {q});

                Assert.Null(result);
                f.PolicingEngine.DidNotReceive().CreateBatch();
            }

            [Fact]
            public void EnqueuesPolicingRequests()
            {
                var f = new BatchPolicingRequestFixture(Db);

                var q1 = Substitute.For<IQueuedPolicingRequest>();
                var q2 = Substitute.For<IQueuedPolicingRequest>();

                f.Subject.Enqueue(new[] {q1, q2});

                q1.Received(1).Enqueue(null, f.PolicingEngine);
                q2.Received(1).Enqueue(null, f.PolicingEngine);
            }

            [Fact]
            public void EnqueuesPolicingRequestsWithBatchNumber()
            {
                var f = new BatchPolicingRequestFixture(Db);

                var batchNo = Fixture.Integer();
                f.PolicingEngine.CreateBatch().ReturnsForAnyArgs(batchNo);
                f.PolicingUtility.IsPoliceImmediately().ReturnsForAnyArgs(true);

                var q1 = Substitute.For<IQueuedPolicingRequest>();
                var q2 = Substitute.For<IQueuedPolicingRequest>();

                f.Subject.Enqueue(new[] {q1, q2});

                q1.Received(1).Enqueue(batchNo, f.PolicingEngine);
                q2.Received(1).Enqueue(batchNo, f.PolicingEngine);
            }
        }

        public class BatchPolicingRequestFixture : IFixture<BatchPolicingRequest>
        {
            public BatchPolicingRequestFixture(InMemoryDbContext db)
            {
                DbContext = Substitute.For<IDbContext>();
                PolicingEngine = Substitute.For<IPolicingEngine>();
                PolicingUtility = Substitute.For<IPolicingUtility>();

                Subject = new BatchPolicingRequest(db, PolicingUtility, PolicingEngine);
            }

            public IDbContext DbContext { get; }

            public IPolicingEngine PolicingEngine { get; }

            public IPolicingUtility PolicingUtility { get; }
            public BatchPolicingRequest Subject { get; }
        }
    }
}