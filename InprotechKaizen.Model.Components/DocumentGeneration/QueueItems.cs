using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;

namespace InprotechKaizen.Model.Components.DocumentGeneration
{
    public interface IQueueItems
    {
        IQueryable<CaseActivityRequest> ForProcessing();
        Task Hold(params int[] queueItemIds);
        Task Error(int queueItemId, string errorMessage);
        Task Complete(int queueItemId, string outputFileName = null);
    }

    public class QueueItems : IQueueItems
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly IActivityRequestHistoryMapper _mapper;

        public QueueItems(IDbContext dbContext, Func<DateTime> now, IActivityRequestHistoryMapper mapper)
        {
            _dbContext = dbContext;
            _now = now;
            _mapper = mapper;
        }

        public IQueryable<CaseActivityRequest> ForProcessing()
        {
            var casesInPolicing = from p in _dbContext.Set<PolicingRequest>()
                                  where p.IsSystemGenerated == 1 && p.CaseId != null
                                  group p by (int) p.CaseId
                                  into g1
                                  select g1.Key;

            return from ar in _dbContext.Set<CaseActivityRequest>()
                   where (ar.Processed == null || ar.Processed == 0)
                         && (ar.HoldFlag == null || ar.HoldFlag == 0)
                         && ar.CaseId != null
                         && ar.LetterNo != null
                         && !casesInPolicing.Contains((int) ar.CaseId)
                   select ar;
        }

        public async Task Hold(params int[] queueItemIds)
        {
            await _dbContext.UpdateAsync(_dbContext.Set<CaseActivityRequest>()
                                                   .Where(_ => queueItemIds.Contains(_.Id)),
                                         x => new CaseActivityRequest
                                         {
                                             HoldFlag = 1,
                                             SystemMessage = null
                                         });

            await _dbContext.SaveChangesAsync();
        }

        public async Task Error(int queueItemId, string errorMessage)
        {
            await _dbContext.UpdateAsync(_dbContext.Set<CaseActivityRequest>()
                                                   .Where(_ => queueItemId == _.Id),
                                         x => new CaseActivityRequest
                                         {
                                             SystemMessage = errorMessage.Truncate(254)
                                         });

            await _dbContext.SaveChangesAsync();
        }

        public async Task Complete(int queueItemId, string outputFileName = null)
        {
            var current
                = await _dbContext.Set<CaseActivityRequest>()
                                     .SingleAsync(_ => _.Id == queueItemId);
            
            var history = _mapper.CopyAsHistory(current, (c, h) =>
            {
                h.FileName = outputFileName ?? current.FileName;
                h.WhenOccurred = _now();
                h.Processed = 1;
            });
            
            _dbContext.Set<CaseActivityHistory>().Add(history);

            _dbContext.Set<CaseActivityRequest>().Remove(current);
            
            await _dbContext.SaveChangesAsync();
        }
    }
}