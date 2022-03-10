using System;
using System.Linq;
using System.Transactions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;

namespace InprotechKaizen.Model.Components.Policing.Monitoring
{
    public interface ISummaryReader
    {
        Summary Read();
    }

    public class SummaryReader : ISummaryReader
    {
        readonly IDbContext _dbContext;

        public SummaryReader(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _dbContext = dbContext;
        }

        public Summary Read()
        {
            using (_dbContext.BeginTransaction(IsolationLevel.ReadUncommitted))
            {
                var policingView = from p in _dbContext.Set<PolicingQueueView>()
                                   select new
                                   {
                                       p.Status,
                                       IdleFor = p.IdleFor <= 120 ? PolicingDuration.Fresh :
                                                  p.IdleFor > 120 && p.IdleFor <= 1200 ? PolicingDuration.Tolerable :
                                                      PolicingDuration.Stuck
                                   };

                var all = (from p in policingView
                           group p by new { p.Status, p.IdleFor }
                           into p
                           select new InterimSummaryRecord
                           {
                               Status = p.Key.Status,
                               IdleFor = p.Key.IdleFor,
                               Count = p.Count()
                           })
                    .ToArray();

                var i = new Detail
                {
                    Fresh = all.InProgress().Fresh().Sum(),
                    Tolerable = all.InProgress().Tolerable().Sum(),
                    Stuck = all.InProgress().Old().Sum()
                };

                var f = new Detail
                {
                    Tolerable = all.Failed().Tolerable().Sum(),
                    Stuck = all.Failed().Old().Sum()
                };

                var o = new Detail
                {
                    Fresh = all.OnHold().Sum()
                };

                var w = new Detail
                {
                    Fresh = all.WaitingToStart().Fresh().Sum(),
                    Tolerable = all.WaitingToStart().Tolerable().Sum(),
                    Stuck = all.WaitingToStart().Old().Sum()
                };

                var e = new Detail
                {
                    Fresh = all.InError().Fresh().Sum(),
                    Tolerable = all.InError().Tolerable().Sum(),
                    Stuck = all.InError().Old().Sum()
                };

                var b = new Detail
                {
                    Fresh = all.Blocked().Fresh().Sum(),
                    Tolerable = all.Blocked().Tolerable().Sum(),
                    Stuck = all.Blocked().Old().Sum()
                };

                return new Summary
                {
                    Total = all.Sum(),
                    InProgress = i,
                    Failed = f,
                    OnHold = o,
                    WaitingToStart = w,
                    InError = e,
                    Blocked = b
                };
            }
        }
    }
}