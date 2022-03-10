using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Work
{
    public interface IPrepaymentWarningCheck
    {
        Task<dynamic> ForCase(int caseKey);
        Task<dynamic> ForName(int nameKey);
    }

    public class PrepaymentWarningCheck : IPrepaymentWarningCheck
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly ISiteControlReader _siteControlReader;
        readonly IQueryable<OpenItem> _allCasePrepayments;

        public PrepaymentWarningCheck(IDbContext dbContext, ISiteControlReader siteControlReader, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _now = now;

            _allCasePrepayments = from o in _dbContext.Set<OpenItem>()
                                  join c in _dbContext.Set<OpenItemCase>()
                                      on new {x1 = o.ItemEntityId, x2 = o.ItemTransactionId, x3 = o.AccountEntityId, x4 = o.AccountDebtorId} equals new {x1 = c.ItemEntityId, x2 = c.ItemTransactionId, x3 = c.AccountEntityId, x4 = c.AccountDebtorId}
                                  select o;
        }

        public async Task<dynamic> ForCase(int caseKey)
        {
            var checkPrepayments = _siteControlReader.Read<bool>(SiteControls.PrepaymentWarnOver);
            if (!checkPrepayments)
                return null;

            var now = _now();
            var caseProperty = _dbContext.Set<Case>().Where(_ => _.Id == caseKey).Select(_ => _.PropertyTypeId);

            var casePrepayments = await (from o in _dbContext.Set<OpenItem>().Where(_ => _.TypeId == ItemType.Prepayment)
                                         join c in _dbContext.Set<OpenItemCase>().Where(_ => _.CaseId == caseKey && _.Status != TransactionStatus.Draft)
                                             on new {x1 = o.ItemEntityId, x2 = o.ItemTransactionId, x3 = o.AccountEntityId, x4 = o.AccountDebtorId} equals new {x1 = c.ItemEntityId, x2 = c.ItemTransactionId, x3 = c.AccountEntityId, x4 = c.AccountDebtorId}
                                         select -o.PreTaxValue * c.LocalValue / o.LocalValue * (c.LocalBalance / c.LocalValue)).SumAsync();

            var debtors = _dbContext.Set<CaseName>().Where(cn => cn.CaseId == caseKey && cn.NameTypeId == KnownNameTypes.Debtor && (cn.StartingDate == null || cn.StartingDate <= now.Date) &&
                                                                 (cn.ExpiryDate == null || cn.ExpiryDate > now.Date));

            var debtorPrepayments = await (from o in _dbContext.Set<OpenItem>()
                                                               .Where(_ => _.TypeId == ItemType.Prepayment && _.Status != TransactionStatus.Draft)
                                                               .Except(_allCasePrepayments)
                                           from d in debtors
                                           where o.AccountDebtorId == d.NameId && (o.PayPropertyType == null || caseProperty.Contains(o.PayPropertyType))
                                           select -o.PreTaxValue * o.LocalBalance / o.LocalValue).SumAsync();

            var totalWip = await _dbContext.Set<WorkInProgress>().Where(_ => _.CaseId == caseKey).Select(_ => _.Balance ?? (decimal?) 0).SumAsync();
            var totalTime = await _dbContext.Set<Diary>().Where(_ => _.CaseId == caseKey && _.TransactionId == null && _.IsTimer < 1 && _.TimeValue != null).Select(_ => _.TimeValue ?? (decimal?) 0).SumAsync();
            totalWip += totalTime ?? 0;

            return new
            {
                CasePrepayments = casePrepayments,
                DebtorPrepayments = debtorPrepayments,
                TotalWip = totalWip,
                Exceeded = (casePrepayments.HasValue || debtorPrepayments.HasValue) && casePrepayments.GetValueOrDefault() + debtorPrepayments.GetValueOrDefault() < totalWip.GetValueOrDefault()
            };
        }

        public async Task<dynamic> ForName(int nameKey)
        {
            var checkPrepayments = _siteControlReader.Read<bool>(SiteControls.PrepaymentWarnOver);
            if (!checkPrepayments)
                return null;

            var debtorPrepayments = await _dbContext.Set<OpenItem>().Where(_ => _.TypeId == ItemType.Prepayment && _.Status != TransactionStatus.Draft && _.AccountDebtorId == nameKey)
                                                    .Except(_allCasePrepayments)
                                                    .Select(o => -o.PreTaxValue * o.LocalBalance / o.LocalValue).SumAsync();

            var totalWip = await _dbContext.Set<WorkInProgress>().Where(_ => _.AccountClientId == nameKey).Select(_ => _.Balance ?? (decimal?) 0).SumAsync();
            var totalTime = await _dbContext.Set<Diary>().Where(_ => _.CaseId == null && _.NameNo == nameKey && _.TransactionId == null && _.IsTimer < 1 && _.TimeValue != null).Select(_ => _.TimeValue ?? (decimal?)0).SumAsync();
            totalWip += totalTime ?? 0;

            return new
            {
                DebtorPrepayments = debtorPrepayments,
                TotalWip = totalWip,
                Exceeded = debtorPrepayments.HasValue && debtorPrepayments.Value < totalWip
            };
        }
    }
}