namespace Inprotech.Tests.Web.Policing
{
    public class PolicingQueueItemFacts
    {
        /*
        public class ReadMethod : FactBase
        {
            [Fact]
            public void ReturnsPolicingErrorsForTheCase()
            {
                var queueItemWaitingToStart = new PolicingQueueItem() { RequestId = 1, OnHoldFlag = 0 };
                var queueItemOnHold = new PolicingQueueItem() { RequestId = 2, OnHoldFlag = 9 };
                var queueItemInProgress = new PolicingQueueItem() { RequestId = 3, InError = false, OnHoldFlag = 3 };
                var queueItemInError = new PolicingQueueItem() { RequestId = 4, InError = true };
                var queueItemHasFailed = new PolicingQueueItem() { RequestId = 5, InError = false, OnHoldFlag = 4, TimeReference = DateTime.Now.AddSeconds(160) };

                var queueItems = new List<PolicingQueueItem>();
                queueItems.Add(queueItemWaitingToStart);
                queueItems.Add(queueItemOnHold);
                queueItems.Add(queueItemInProgress);
                queueItems.Add(queueItemInError);
                queueItems.Add(queueItemHasFailed);

                var filter = QueueReaderHelper.StatusFilter;

                var result = queueItems.AsQueryable().Where(filter["waiting-to-start"]);
                Assert.Equal(1, result.Count());
                Assert.Equal(1, result.First().RequestId);

                result = queueItems.AsQueryable().Where(filter["on-hold"]);
                Assert.Equal(1, result.Count());
                Assert.Equal(2, result.First().RequestId);

                result = queueItems.AsQueryable().Where(filter["in-progress"]);
                Assert.Equal(1, result.Count());
                Assert.Equal(3, result.First().RequestId);

                result = queueItems.AsQueryable().Where(filter["in-error"]);
                Assert.Equal(1, result.Count());
                Assert.Equal(4, result.First().RequestId);

                result = queueItems.AsQueryable().Where(filter["failed"]);
                Assert.Equal(1, result.Count());
                Assert.Equal(5, result.First().RequestId);

                result = queueItems.AsQueryable().Where(filter["all"]);
                Assert.Equal(5, result.Count());
            }
        }
        */
    }
}