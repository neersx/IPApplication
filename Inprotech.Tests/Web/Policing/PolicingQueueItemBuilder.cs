using System;
using Inprotech.Tests.Web.Builders;
using Inprotech.Web.Policing;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingQueueItemBuilder : IBuilder<PolicingQueueItem>
    {
        public string Status { get; set; }

        public DateTime? Requested { get; set; }

        public PolicingQueueItem Build()
        {
            return new PolicingQueueItem
            {
                //Status = Status ?? PolicingItemStatus.WaitingToStart,
                Requested = Requested ?? Fixture.Today()
            };
        }
    }
}