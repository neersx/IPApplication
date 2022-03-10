using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Policing;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.DataEntryTasks.Policing
{
    public static class PolicingRequestProcessorFacts
    {
        public class ProcessMethod : FactBase
        {
            [Fact]
            public void CallsEnqueueInQueuedPolicingRequestWithBatchNumber()
            {
                var f = new QueuedPolicingRequestProcessorFixture()
                    .ReturnsShouldPoliceImmediatelyOfWhatsPassedIn();

                var request = Substitute.For<IQueuedPolicingRequest>();

                f.Subject.Process(
                                  new DataEntryTask(),
                                  new[] {new PolicingRequests(new[] {request}, true)});

                request.Received(1).Enqueue(f.GeneratedBatchNumber, f.PolicingEngine);
            }

            [Fact]
            public void CreatesABatchIfPoliceImmediatelyInBackgroundIsOn()
            {
                var f = new QueuedPolicingRequestProcessorFixture();

                f.BatchPolicingRequest
                 .ShouldPoliceImmediately(Arg.Any<bool?>())
                 .ReturnsForAnyArgs(true);

                var result = f.Subject.Process(
                                               new DataEntryTask(),
                                               new[] {new PolicingRequests(new IQueuedPolicingRequest[0])});

                Assert.Equal(f.GeneratedBatchNumber, result);
                f.BatchPolicingRequest.ReceivedWithAnyArgs(1).ShouldPoliceImmediately();
            }

            [Fact]
            public void CreatesABatchIfPoliceImmediatelyIsOn()
            {
                var f = new QueuedPolicingRequestProcessorFixture();

                f.BatchPolicingRequest
                 .ShouldPoliceImmediately(Arg.Any<bool?>())
                 .ReturnsForAnyArgs(true);

                var result = f.Subject.Process(
                                               new DataEntryTask(),
                                               new[] {new PolicingRequests(new IQueuedPolicingRequest[0])});

                Assert.Equal(f.GeneratedBatchNumber, result);
                f.BatchPolicingRequest.ReceivedWithAnyArgs(1).ShouldPoliceImmediately();
            }

            [Fact]
            public void CreatesBatchIfPolicingImmediateSettingIsSetForAnEvent()
            {
                var f = new QueuedPolicingRequestProcessorFixture()
                    .ReturnsShouldPoliceImmediatelyOfWhatsPassedIn();

                var result = f.Subject.Process(
                                               new DataEntryTask(),
                                               new[] {new PolicingRequests(new IQueuedPolicingRequest[0], true)});

                Assert.Equal(f.GeneratedBatchNumber, result);
                f.BatchPolicingRequest.ReceivedWithAnyArgs(1).ShouldPoliceImmediately(Arg.Any<bool?>());
            }

            [Fact]
            public void CreatesBatchIfPolicingImmediateSettingIsSetInDataEntryTask()
            {
                var f = new QueuedPolicingRequestProcessorFixture()
                    .ReturnsShouldPoliceImmediatelyOfWhatsPassedIn();

                var result = f.Subject.Process(
                                               new DataEntryTask {ShouldPoliceImmediate = true},
                                               new[] {new PolicingRequests(new IQueuedPolicingRequest[0])});

                Assert.Equal(f.GeneratedBatchNumber, result);
                f.BatchPolicingRequest.ReceivedWithAnyArgs(1).ShouldPoliceImmediately();
            }

            [Fact]
            public void DoesNotCreateABatchIfNoPolicingRequestsSpecified()
            {
                Assert.Null(
                            new QueuedPolicingRequestProcessorFixture().Subject
                                                                       .Process(
                                                                                new DataEntryTask(),
                                                                                new PolicingRequests[0]));
            }

            [Fact]
            public void EnqueuesAllRequestsToPolicingEngine()
            {
                var f = new QueuedPolicingRequestProcessorFixture();

                var request = Substitute.For<IQueuedPolicingRequest>();

                f.Subject.Process(
                                  new DataEntryTask(),
                                  new[] {new PolicingRequests(new[] {request})});

                request.Received(1).Enqueue(null, f.PolicingEngine);
            }

            [Fact]
            public void WillNotCreateABatchIfPoliceContinouslyIsOn()
            {
                var f = new QueuedPolicingRequestProcessorFixture();

                f.BatchPolicingRequest
                 .ShouldPoliceImmediately(Arg.Any<bool?>())
                 .ReturnsForAnyArgs(false); /* police continuously will cause the function to return false */

                var result = f.Subject.Process(
                                               new DataEntryTask(),
                                               new[] {new PolicingRequests(new IQueuedPolicingRequest[0])});

                Assert.Null(result);
                f.BatchPolicingRequest.ReceivedWithAnyArgs(1).ShouldPoliceImmediately(Arg.Any<bool?>());
            }
        }
    }

    public class QueuedPolicingRequestProcessorFixture : IFixture<PolicingRequestProcessor>
    {
        public QueuedPolicingRequestProcessorFixture()
        {
            GeneratedBatchNumber = 1;
            PolicingEngine = Substitute.For<IPolicingEngine>();
            PolicingEngine.CreateBatch().Returns(GeneratedBatchNumber);
            BatchPolicingRequest = Substitute.For<IBatchPolicingRequest>();
            Subject = new PolicingRequestProcessor(PolicingEngine, BatchPolicingRequest);
        }

        public IPolicingEngine PolicingEngine { get; }

        public IBatchPolicingRequest BatchPolicingRequest { get; }

        public int GeneratedBatchNumber { get; }

        public PolicingRequestProcessor Subject { get; }

        public QueuedPolicingRequestProcessorFixture ReturnsShouldPoliceImmediatelyOfWhatsPassedIn()
        {
            BatchPolicingRequest.ShouldPoliceImmediately(Arg.Any<bool?>())
                                .Returns(x => ((bool?) x[0]).GetValueOrDefault());
            return this;
        }
    }
}