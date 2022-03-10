using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using Xunit;

namespace Inprotech.Tests.Model.Components.Policing
{
    public class InterimSummaryRecordFacts
    {
        IEnumerable<InterimSummaryRecord> GetRecords()
        {
            yield return new InterimSummaryRecord {Status = PolicingItemStatus.Error, IdleFor = PolicingDuration.Fresh, Count = 3};
            yield return new InterimSummaryRecord {Status = PolicingItemStatus.Error, IdleFor = PolicingDuration.Stuck, Count = 2};
            yield return new InterimSummaryRecord {Status = PolicingItemStatus.InProgress, IdleFor = PolicingDuration.Stuck, Count = 4};
            yield return new InterimSummaryRecord {Status = PolicingItemStatus.OnHold, IdleFor = PolicingDuration.Stuck, Count = 5};
            yield return new InterimSummaryRecord {Status = PolicingItemStatus.OnHold, IdleFor = PolicingDuration.Fresh, Count = 4};
            yield return new InterimSummaryRecord {Status = PolicingItemStatus.WaitingToStart, IdleFor = PolicingDuration.Tolerable, Count = 6};
            yield return new InterimSummaryRecord {Status = PolicingItemStatus.Failed, IdleFor = PolicingDuration.Tolerable, Count = 1};
            yield return new InterimSummaryRecord {Status = PolicingItemStatus.Blocked, IdleFor = PolicingDuration.Fresh, Count = 2};
        }

        [Fact]
        public void BlockedReturnsBlockedRecords()
        {
            var result = GetRecords().Blocked().ToList();
            Assert.Single(result);
            Assert.Equal(2, result.First().Count);
        }

        [Fact]
        public void FailedReturnsFailedRecords()
        {
            var result = GetRecords().Failed().ToList();
            Assert.Single(result);
            Assert.Equal(1, result.First().Count);
        }

        [Fact]
        public void FreshOnesReturnsFreshRecords()
        {
            var result = GetRecords().Fresh().OrderBy(_ => _.Count).ToArray();
            Assert.Equal(3, result.Length);
            Assert.Equal(2, result.First().Count);
            Assert.Equal(4, result.Last().Count);
        }

        [Fact]
        public void InErrorReturnsTotalRecordsWithAnyDuration()
        {
            var result = GetRecords().InError().OrderBy(_ => _.Count).ToArray();
            Assert.Equal(2, result.Length);
            Assert.Equal(2, result.First().Count);
            Assert.Equal(3, result.Last().Count);
        }

        [Fact]
        public void InProgressReturnsProgress()
        {
            var result = GetRecords().InProgress().ToList();
            Assert.Single(result);
            Assert.Equal(4, result.First().Count);
        }

        [Fact]
        public void IsWaitingToStartReturnsWaitingToStartRecords()
        {
            var result = GetRecords().WaitingToStart().ToList();
            Assert.Single(result);
            Assert.Equal(6, result.First().Count);
        }

        [Fact]
        public void OldOnesReturnsStuckRecords()
        {
            var result = GetRecords().Old().OrderBy(_ => _.Count).ToArray();
            Assert.Equal(3, result.Length);
            Assert.Equal(2, result.First().Count);
            Assert.Equal(5, result.Last().Count);
        }

        [Fact]
        public void OnHoldReturnsOnHoldRecords()
        {
            var result = GetRecords().OnHold().OrderBy(_ => _.Count).ToArray();
            Assert.Equal(2, result.Length);
            Assert.Equal(4, result.First().Count);
            Assert.Equal(5, result.Last().Count);
        }

        [Fact]
        public void SumErrorsReturnsTotalSum()
        {
            var total = GetRecords().InError().Sum();
            Assert.Equal(3 + 2, total);
        }

        [Fact]
        public void SumFreshErrorsReturnsSumForFresh()
        {
            var total = GetRecords().InError().Fresh().Sum();
            Assert.Equal(3, total);
        }

        [Fact]
        public void SumOnHoldReturnsTotalSum()
        {
            var total = GetRecords().OnHold().Sum();
            Assert.Equal(5 + 4, total);
        }

        [Fact]
        public void TolerableOnesReturnsTolerableRecords()
        {
            var result = GetRecords().Tolerable().OrderBy(_ => _.Count).ToArray();
            Assert.Equal(2, result.Length);
            Assert.Equal(1, result.First().Count);
            Assert.Equal(6, result.Last().Count);
        }
    }
}