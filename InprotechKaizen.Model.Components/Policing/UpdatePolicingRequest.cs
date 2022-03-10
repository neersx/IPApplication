using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using Z.EntityFramework.Plus;

#pragma warning disable 618

namespace InprotechKaizen.Model.Components.Policing
{
    public interface IUpdatePolicingRequest
    {
        void Release(int[] items);
        void Hold(int[] items);
        void Delete(int[] items);

        [SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "RunTime")]
        void EditNextRunTime(DateTime nextRuntime, int[] items);
    }

    public class UpdatePolicingRequest : IUpdatePolicingRequest
    {
        readonly IDbContext _dbContext;

        public UpdatePolicingRequest(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public void Release(int[] items)
        {
            GetPolicingItemsToUpdate(items)
                .Where(_ => _.OnHold != 0)
                .Update(_ => new PolicingRequest {OnHold = 0});
        }

        public void Hold(int[] items)
        {
            GetPolicingItemsToUpdate(items)
                .Where(_ => _.OnHold != 9)
                .Update(_ => new PolicingRequest {OnHold = 9});
        }

        public void Delete(int[] items)
        {
            GetPolicingItemsToUpdate(items).Delete();
        }

        public void EditNextRunTime(DateTime nextRuntime, int[] items)
        {
            GetPolicingItemsToUpdate(items)
                .Update(_ => new PolicingRequest {ScheduledDateTime = nextRuntime, OnHold = 0});
        }

        IQueryable<PolicingRequest> GetPolicingItemsToUpdate(IEnumerable<int> items)
        {
            return _dbContext.Set<PolicingRequest>()
                             .Where(_ => items.Contains(_.RequestId));
        }
    }
}