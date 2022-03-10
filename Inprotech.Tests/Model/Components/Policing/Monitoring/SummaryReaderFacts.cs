using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using InprotechKaizen.Model.Policing;
using Xunit;

namespace Inprotech.Tests.Model.Components.Policing.Monitoring
{
    public class SummaryReaderFacts : FactBase
    {
        const int FreshDuration = 60;
        const int TolerableDuration = 150;
        const int StuckDuration = 1250;

        [Theory]
        [InlineData(PolicingItemStatus.OnHold, FreshDuration, 1)]
        [InlineData(PolicingItemStatus.Blocked, TolerableDuration, 0)]
        [InlineData(PolicingItemStatus.InProgress, FreshDuration, 0)]
        [InlineData(PolicingItemStatus.WaitingToStart, FreshDuration, 0)]
        public void ReturnOnHoldCountOfThoseWithHoldFlagSet(string status, int idleForSec, int expectedCount)
        {
            BuildQueueView(status, idleForSec);

            var r = SummaryReaderFixture().Read();

            Assert.Equal(1, r.Total);
            Assert.Equal(expectedCount, r.OnHold.Total);
        }

        [Theory]
        [InlineData(FreshDuration, 0)]
        [InlineData(TolerableDuration, 1)]
        [InlineData(StuckDuration, 1)]
        public void FailedCanNotBeFresh(int idleFor, int expectedCount)
        {
            BuildQueueView(PolicingItemStatus.Failed, idleFor);

            var r = SummaryReaderFixture().Read();

            Assert.Equal(1, r.Total);
            Assert.Equal(expectedCount, r.Failed.Total);
        }

        [Theory]
        [InlineData(FreshDuration, 1)]
        [InlineData(TolerableDuration, 1)]
        [InlineData(StuckDuration, 1)]
        public void OnHoldShouldNotConsiderIdleForDuration(int idleFor, int expectedCount)
        {
            BuildQueueView(PolicingItemStatus.OnHold, idleFor);

            var r = SummaryReaderFixture().Read();

            Assert.Equal(1, r.Total);
            Assert.Equal(expectedCount, r.OnHold.Total);
            Assert.Equal(expectedCount, r.OnHold.Fresh);
            Assert.Equal(0, r.OnHold.Tolerable);
            Assert.Equal(0, r.OnHold.Stuck);
        }

        SummaryReader SummaryReaderFixture()
        {
            return new SummaryReader(Db);
        }

        void BuildQueueView(string status, int idleForSec)
        {
#pragma warning disable 618
            new PolicingQueueView
            {
                Status = status,
                IdleFor = idleForSec
            }.In(Db);
#pragma warning restore 618
        }

        [Fact]
        public void ReturnCountOfEachStatus()
        {
            BuildQueueView(PolicingItemStatus.OnHold, FreshDuration);
            BuildQueueView(PolicingItemStatus.Blocked, FreshDuration);
            BuildQueueView(PolicingItemStatus.InProgress, FreshDuration);
            BuildQueueView(PolicingItemStatus.WaitingToStart, FreshDuration);
            BuildQueueView(PolicingItemStatus.Error, FreshDuration);
            BuildQueueView(PolicingItemStatus.Failed, TolerableDuration);

            var r = SummaryReaderFixture().Read();

            Assert.Equal(6, r.Total);
            Assert.Equal(1, r.OnHold.Total);
            Assert.Equal(1, r.Blocked.Total);
            Assert.Equal(1, r.InProgress.Total);
            Assert.Equal(1, r.WaitingToStart.Total);
            Assert.Equal(1, r.InError.Total);
            Assert.Equal(1, r.Failed.Total);
        }

        [Fact]
        public void ReturnCountWithRespectToIdleForDuration()
        {
            BuildQueueView(PolicingItemStatus.OnHold, FreshDuration);

            BuildQueueView(PolicingItemStatus.Blocked, FreshDuration);
            BuildQueueView(PolicingItemStatus.Blocked, TolerableDuration);
            BuildQueueView(PolicingItemStatus.Blocked, StuckDuration);

            BuildQueueView(PolicingItemStatus.InProgress, FreshDuration);
            BuildQueueView(PolicingItemStatus.InProgress, TolerableDuration);
            BuildQueueView(PolicingItemStatus.InProgress, StuckDuration);

            BuildQueueView(PolicingItemStatus.WaitingToStart, FreshDuration);
            BuildQueueView(PolicingItemStatus.WaitingToStart, FreshDuration);
            BuildQueueView(PolicingItemStatus.WaitingToStart, TolerableDuration);
            BuildQueueView(PolicingItemStatus.WaitingToStart, StuckDuration);

            BuildQueueView(PolicingItemStatus.Error, FreshDuration);
            BuildQueueView(PolicingItemStatus.Error, TolerableDuration);
            BuildQueueView(PolicingItemStatus.Error, StuckDuration);

            BuildQueueView(PolicingItemStatus.Failed, TolerableDuration);
            BuildQueueView(PolicingItemStatus.Failed, StuckDuration);

            var r = SummaryReaderFixture().Read();

            Assert.Equal(16, r.Total);
            Assert.Equal(1, r.OnHold.Total);

            Assert.Equal(3, r.Blocked.Total);
            Assert.Equal(1, r.Blocked.Fresh);
            Assert.Equal(1, r.Blocked.Tolerable);
            Assert.Equal(1, r.Blocked.Stuck);

            Assert.Equal(3, r.InProgress.Total);
            Assert.Equal(1, r.InProgress.Fresh);
            Assert.Equal(1, r.InProgress.Tolerable);
            Assert.Equal(1, r.InProgress.Stuck);

            Assert.Equal(4, r.WaitingToStart.Total);
            Assert.Equal(2, r.WaitingToStart.Fresh);
            Assert.Equal(1, r.WaitingToStart.Tolerable);
            Assert.Equal(1, r.WaitingToStart.Stuck);

            Assert.Equal(3, r.InError.Total);
            Assert.Equal(1, r.InError.Fresh);
            Assert.Equal(1, r.InError.Tolerable);
            Assert.Equal(1, r.InError.Stuck);

            Assert.Equal(2, r.Failed.Total);
            Assert.Equal(0, r.Failed.Fresh);
            Assert.Equal(1, r.Failed.Tolerable);
            Assert.Equal(1, r.Failed.Stuck);
        }
    }
}