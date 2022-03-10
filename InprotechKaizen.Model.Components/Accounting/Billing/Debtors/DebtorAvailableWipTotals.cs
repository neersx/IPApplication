using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Debtors
{
    public interface IDebtorAvailableWipTotals
    {
        Task<decimal?> ForNewBill(int[] caseIds, int? debtorId, int? entityId);
        Task<decimal?> ForDraftBill(int[] caseIds, int debtorId, int? entityId, int transId);
    }

    public class DebtorAvailableWipTotals : IDebtorAvailableWipTotals
    {
        readonly IDbContext _dbContext;
        readonly IBillingSiteSettingsResolver _billingSiteSettingsResolver;

        public DebtorAvailableWipTotals(IDbContext dbContext, IBillingSiteSettingsResolver billingSiteSettingsResolver)
        {
            _dbContext = dbContext;
            _billingSiteSettingsResolver = billingSiteSettingsResolver;
        }
        
        public async Task<decimal?> ForNewBill(int[] caseIds, int? debtorId, int? entityId)
        {
            if (caseIds == null) throw new ArgumentNullException(nameof(caseIds));
            var interEntityBilling = await GetInterEntityBillingSetting();
            
            var totalWip = !caseIds.Any()
                ? await (from wip in _dbContext.Set<WorkInProgress>()
                                where wip.Status == TransactionStatus.Active
                                      && (interEntityBilling || wip.EntityId == entityId)
                                      && wip.AccountClientId == debtorId
                                      && wip.CaseId == null
                                select wip)
                               .SumAsync(wip => wip.Balance)
                : await (from wip in _dbContext.Set<WorkInProgress>()
                                where wip.Status == TransactionStatus.Active
                                      && (interEntityBilling || wip.EntityId == entityId)
                                      && wip.CaseId != null && caseIds.Contains((int) wip.CaseId)
                                      && wip.AccountClientId == debtorId
                                select wip)
                               .SumAsync(wip => wip.Balance);

            return totalWip.GetValueOrDefault();
        }

        public async Task<decimal?> ForDraftBill(int[] caseIds, int debtorId, int? entityId, int transId)
        {
            if (caseIds == null) throw new ArgumentNullException(nameof(caseIds));
            
            var totalWip = await (from b in _dbContext.Set<BilledItem>()
                                  where b.AccountDebtorId == debtorId
                                        && b.EntityId == entityId
                                        && b.TransactionId == transId
                                  select b)
                .SumAsync(b => b.BilledValue);

            return totalWip.GetValueOrDefault() + await ForNewBill(caseIds, debtorId, entityId);
        }

        async Task<bool> GetInterEntityBillingSetting()
        {
            var settings = await _billingSiteSettingsResolver.Resolve(new BillingSiteSettingsScope {Scope = SettingsResolverScope.WithoutUserSpecificSettings});
            return settings.InterEntityBilling;
        }
    }
}