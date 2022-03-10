using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting
{
    public interface IAccountingProvider
    {
        Task<AgeingBrackets> GetAgeingBrackets();
        Task<dynamic> GetAgedWipTotals(int caseKey, DateTime? baseDate, int current, int previousPeriod, int lastPeriod);
        Task<dynamic> GetAgedReceivableTotals(int nameId, DateTime? baseDate, int current, int previousPeriod, int lastPeriod);
        Task<decimal> UnbilledWipFor(int caseId, DateTime? startDate = null, DateTime? endDate = null);
        Task<DateTime?> GetLastInvoiceDate(int caseId);
    }

    public class AccountingProvider : IAccountingProvider
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _clock;

        public AccountingProvider(IDbContext dbContext, Func<DateTime> clock)
        {
            _dbContext = dbContext;
            _clock = clock;
        }

        public async Task<AgeingBrackets> GetAgeingBrackets()
        {
            var now = _clock().Date;
            var endDate = await _dbContext.Set<Period>().Where(_ => _.StartDate <= now && _.EndDate >= now).ToArrayAsync();

            if (!endDate.Any()) return new AgeingBrackets();

            var maxBracket = endDate.OrderByDescending(_ => _.Id).First();
            var bracket1 = await _dbContext.Set<Period>().Where(_ => _.Id < maxBracket.Id).OrderByDescending(_ => _.Id).FirstOrDefaultAsync();
            var bracket2 = await _dbContext.Set<Period>().Where(_ => _.Id < bracket1.Id).OrderByDescending(_ => _.Id).FirstOrDefaultAsync();

            var period0 = new {maxBracket.StartDate, maxBracket.EndDate};
            var period1 = bracket1?.StartDate;
            var period2 = bracket2?.StartDate;
            return new AgeingBrackets
            {
                Bracket0 = (period0.EndDate - period0.StartDate).Days + 1,
                Bracket1 = (period0.EndDate - period1)?.Days + 1,
                Bracket2 = (period0.EndDate - period2)?.Days + 1,
                BaseDate = endDate.FirstOrDefault()?.EndDate
            };
        }

        public async Task<dynamic> GetAgedWipTotals(int caseKey, DateTime? baseDate, int current, int previousPeriod, int lastPeriod)
        {
            var now = _clock();
            var caseWip = from w in _dbContext.Set<WorkInProgress>()
                          join n in _dbContext.Set<Name>() on w.EntityId equals n.Id
                          where w.CaseId == caseKey
                                && w.Status != 0
                                && w.TransactionDate <= now
                          group new {EntityName = n.LastName, Wip = w} by new {EntityNo = w.EntityId}
                          into wipByEntity
                          select wipByEntity;

            var sumByEntity = caseWip.Select(_ => new
            {
                Bracket0Total = _.Where(__ => DbFuncs.DiffDays(__.Wip.TransactionDate, baseDate) < current).Sum(x => x.Wip.Balance) ?? 0,
                Bracket1Total = _.Where(__ => current < DbFuncs.DiffDays(__.Wip.TransactionDate, baseDate)
                                              && DbFuncs.DiffDays(__.Wip.TransactionDate, baseDate) < (previousPeriod - 1)).Sum(x => x.Wip.Balance) ?? 0,
                Bracket2Total = _.Where(__ => previousPeriod < DbFuncs.DiffDays(__.Wip.TransactionDate, baseDate)
                                              && DbFuncs.DiffDays(__.Wip.TransactionDate, baseDate) < (lastPeriod - 1)).Sum(x => x.Wip.Balance) ?? 0,
                Bracket3Total = _.Where(__ => DbFuncs.DiffDays(__.Wip.TransactionDate, baseDate) >= lastPeriod).Sum(x => x.Wip.Balance) ?? 0,
                Total = _.Sum(x => x.Wip.Balance) ?? 0,
                _.FirstOrDefault().EntityName
            });
            return await sumByEntity.ToArrayAsync();
        }

        public async Task<dynamic> GetAgedReceivableTotals(int nameId, DateTime? baseDate, int current, int previousPeriod, int lastPeriod)
        {
            var now = _clock();
            var items = from o in _dbContext.Set<OpenItem>()
                        join n in _dbContext.Set<Name>() on o.AccountEntityId equals n.Id
                        where o.AccountDebtorId == nameId
                              && o.Status != (short) TransactionStatus.Draft
                              && o.ItemDate <= now
                        group new {EntityName = n.LastName, OpenItem = o} by new {o.AccountEntityId}
                        into wipByEntity
                        select wipByEntity;

            var sumByEntity = items.Select(_ => new
            {
                Bracket0Total = _.Where(__ => DbFuncs.DiffDays(__.OpenItem.ItemDate, baseDate) < current).Sum(x => x.OpenItem.LocalBalance) ?? 0,
                Bracket1Total = _.Where(__ => current < DbFuncs.DiffDays(__.OpenItem.ItemDate, baseDate)
                                              && DbFuncs.DiffDays(__.OpenItem.ItemDate, baseDate) < (previousPeriod - 1)).Sum(x => x.OpenItem.LocalBalance) ?? 0,
                Bracket2Total = _.Where(__ => previousPeriod < DbFuncs.DiffDays(__.OpenItem.ItemDate, baseDate)
                                              && DbFuncs.DiffDays(__.OpenItem.ItemDate, baseDate) < (lastPeriod - 1)).Sum(x => x.OpenItem.LocalBalance) ?? 0,
                Bracket3Total = _.Where(__ => DbFuncs.DiffDays(__.OpenItem.ItemDate, baseDate) >= lastPeriod).Sum(x => x.OpenItem.LocalBalance) ?? 0,
                Total = _.Sum(x => x.OpenItem.LocalBalance) ?? 0,
                _.FirstOrDefault().EntityName
            });
            return await sumByEntity.ToArrayAsync();
        }

        public async Task<decimal> UnbilledWipFor(int caseId, DateTime? startDate = null, DateTime? endDate = null)
        {
            return await (from w in _dbContext.Set<WorkInProgress>()
                          where w.CaseId == caseId && w.Status != 0 &&
                                (startDate == null || w.TransactionDate >= startDate) && (endDate == null || w.TransactionDate <= endDate)
                          select w.Balance).SumAsync() ?? 0;
        }

        public Task<DateTime?> GetLastInvoiceDate(int caseId)
        {
            var allowedTypes = new[] {ItemType.DebitNote, ItemType.InternalDebitNote};
            var openItem = _dbContext.Set<OpenItem>().Where(_ => _.Status == TransactionStatus.Active && _.AssociatedOpenItemNo == null && allowedTypes.Contains(_.TypeId));
            var workHistory = _dbContext.Set<WorkHistory>().Where(_ => _.CaseId == caseId);

            return (from o in openItem
                    join w in workHistory on o.ItemTransactionId equals w.RefTransactionId
                    select o.ItemDate).MaxAsync();
        }
    }
}