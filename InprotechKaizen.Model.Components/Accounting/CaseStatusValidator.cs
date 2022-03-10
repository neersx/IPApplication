using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting
{
    public interface ICaseStatusValidator
    {
        Task<bool> IsRestrictedCaseStatus(int caseId, short? statusId);
        Task<bool> IsCaseStatusRestrictedForPrepayment(int caseId);
        Task<bool> IsCaseStatusRestrictedForWip(int caseId);
        Task<bool> HasAnyBillCasesRestricted(int entityId, int transactionId);
        IQueryable<Case> GetCasesRestrictedForBilling(int[] caseIds);
        Task<IEnumerable<int>> GetCaseDebtors(int caseIds);
        IQueryable<Case> ListRestrictedCasesForStatusChange(int[] caseIds, short? statusId);
    }

    public class CaseStatusValidator : ICaseStatusValidator
    {
        readonly IDbContext _dbContext;

        public CaseStatusValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<bool> IsRestrictedCaseStatus(int caseId, short? statusId)
        {
            if (statusId == null) throw new ArgumentNullException(nameof(statusId));

            var status = await _dbContext.Set<Status>().SingleAsync(st => st.Id == statusId);
            var isPreventWip = status.PreventWip == true;
            var isPreventBilling = status.PreventBilling == true;

            return (isPreventWip || isPreventBilling) && await HasUnpostedTimeEntries(caseId)
                   || isPreventBilling && await HasWip(caseId);
        }

        public Task<bool> IsCaseStatusRestrictedForWip(int caseId)
        {
            return (from c in _dbContext.Set<Case>()
                    join s in _dbContext.Set<Status>() on c.StatusCode equals s.Id
                    where s.PreventWip == true && c.Id == caseId
                    select c).AnyAsync();
        }

        public Task<bool> IsCaseStatusRestrictedForPrepayment(int caseId)
        {
            return (from c in _dbContext.Set<Case>()
                    join s in _dbContext.Set<Status>() on c.StatusCode equals s.Id
                    where s.PreventPrepayment == true && c.Id == caseId
                    select c).AnyAsync();
        }

        public async Task<IEnumerable<int>> GetCaseDebtors(int caseId)
        {
            return await (from cn in _dbContext.Set<CaseName>()
                          where cn.NameTypeId == KnownNameTypes.Debtor
                                && cn.CaseId == caseId
                          select cn).Select(_ => _.NameId).ToArrayAsync();
        }

        public IQueryable<Case> GetCasesRestrictedForBilling(int[] caseIds)
        {
            return from c in _dbContext.Set<Case>()
                   join s in _dbContext.Set<Status>() on c.StatusCode equals s.Id
                   where caseIds.Contains(c.Id) && s.PreventBilling == true
                   select c;
        }

        public async Task<bool> HasAnyBillCasesRestricted(int entityId, int transactionId)
        {
            var openItemStatus = await (from oi in _dbContext.Set<OpenItem>()
                                        where oi.ItemEntityId == entityId && oi.ItemTransactionId == transactionId
                                        select oi.Status).FirstOrDefaultAsync();

            var casesWithRestriction = from c in _dbContext.Set<Case>()
                                       join s in _dbContext.Set<Status>() on c.StatusCode equals s.Id
                                       where s.PreventBilling == true
                                       select c;

            return openItemStatus == TransactionStatus.Active || openItemStatus == TransactionStatus.Reversed
                ? await (from wh in _dbContext.Set<WorkHistory>()
                         join cwr in casesWithRestriction on wh.CaseId equals cwr.Id
                         where wh.RefEntityId == entityId && wh.RefTransactionId == transactionId
                         select wh).AnyAsync()
                : await (from wip in _dbContext.Set<WorkInProgress>()
                         join cwr in casesWithRestriction on wip.CaseId equals cwr.Id
                         join bi in _dbContext.Set<BilledItem>() on
                             new
                             {
                                 WipEntityNo = wip.EntityId,
                                 WipTransNo = wip.TransactionId,
                                 WipSeqNo = wip.WipSequenceNo
                             }
                             equals new
                             {
                                 WipEntityNo = bi.WipEntityId,
                                 WipTransNo = bi.WipTransactionId,
                                 WipSeqNo = bi.WipSequenceNo
                             }
                             into bi1
                         from bi in bi1
                         where bi.EntityId == entityId && bi.TransactionId == transactionId
                         select bi).AnyAsync();
        }

        public IQueryable<Case> ListRestrictedCasesForStatusChange(int[] caseIds, short? statusId)
        {
            if (statusId == null) throw new ArgumentNullException(nameof(statusId));

            var emptySet = from c in _dbContext.Set<Case>()
                           where false
                           select c;

            if (!caseIds.Any()) return emptySet;

            var status = _dbContext.Set<Status>().First(st => st.Id == statusId);
            var isPreventWip = status.PreventWip == true;
            var isPreventBilling = status.PreventBilling == true;

            if (isPreventWip || isPreventBilling)
            {
                var unpostedTimeForCases = from c in _dbContext.Set<Case>()
                                           join d in _dbContext.Set<Diary>() on c.Id equals d.CaseId
                                           where caseIds.Contains(c.Id)
                                                 && d.WipEntityId == null
                                                 && d.TransactionId == null
                                                 && d.IsTimer == 0
                                                 && d.TimeValue > 0
                                           select c;

                if (isPreventBilling)
                {
                    var caseWips = from c in _dbContext.Set<Case>()
                                   join wip in _dbContext.Set<WorkInProgress>() on c.Id equals wip.CaseId
                                   where caseIds.Contains(c.Id)
                                   select c;

                    return (from c in _dbContext.Set<Case>()
                            where caseWips.Contains(c) || unpostedTimeForCases.Contains(c)
                            select c).Distinct();
                }

                return (from c in _dbContext.Set<Case>()
                        where unpostedTimeForCases.Contains(c)
                        select c).Distinct();
            }

            return emptySet;
        }

        async Task<bool> HasUnpostedTimeEntries(int caseId)
        {
            return await _dbContext.Set<Diary>().AnyAsync(d => d.CaseId == caseId
                                                               && d.WipEntityId == null
                                                               && d.TransactionId == null
                                                               && d.IsTimer == 0
                                                               && d.TimeValue > 0);
        }

        async Task<bool> HasWip(int caseId)
        {
            return await _dbContext.Set<WorkInProgress>().AnyAsync(wip => wip.CaseId == caseId);
        }
    }
}