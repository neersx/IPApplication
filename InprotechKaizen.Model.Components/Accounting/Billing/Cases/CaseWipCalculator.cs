using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Cases
{
    public interface ICaseWipCalculator
    {
        Task<decimal?> GetUnlockedAvailableWip(int caseId, int? entityId);

        Task<decimal?> GetTotalAvailableWip(int caseId, int? entityId);

        Task<Dictionary<int, decimal?>> GetUnlockedAvailableWip(int[] caseIds, int? entityId);

        Task<Dictionary<int, decimal?>> GetTotalAvailableWip(int[] caseIds, int? entityId);

        Task<Dictionary<int, IEnumerable<string>>> GetDraftBillsByCase(params int[] caseIds);
    }

    public class CaseWipCalculator : ICaseWipCalculator
    {
        readonly IBillingSiteSettingsResolver _billingSiteSettingsResolver;
        readonly IDbContext _dbContext;

        public CaseWipCalculator(IDbContext dbContext, IBillingSiteSettingsResolver billingSiteSettingsResolver)
        {
            _dbContext = dbContext;
            _billingSiteSettingsResolver = billingSiteSettingsResolver;
        }

        public async Task<decimal?> GetUnlockedAvailableWip(int caseId, int? entityId)
        {
            return (await GetUnlockedAvailableWip(new[] {caseId}, entityId)).Get(caseId);
        }

        public async Task<decimal?> GetTotalAvailableWip(int caseId, int? entityId)
        {
            return (await GetTotalAvailableWip(new[] {caseId}, entityId)).Get(caseId);
        }

        public async Task<Dictionary<int, decimal?>> GetUnlockedAvailableWip(int[] caseIds, int? entityId)
        {
            var interEntityBilling = await GetInterEntityBillingSetting();

            return await (from wip in _dbContext.Set<WorkInProgress>()
                          where wip.Status == TransactionStatus.Active
                                && (interEntityBilling || wip.EntityId == entityId)
                                && wip.CaseId != null && caseIds.Contains((int) wip.CaseId)
                          group wip by wip.CaseId
                          into g1
                          select new
                          {
                              CaseId = (int) g1.Key,
                              WipBalance = g1.DefaultIfEmpty().Sum(_ => _.Balance)
                          }).ToDictionaryAsync(k => k.CaseId, v => v.WipBalance);
        }

        public async Task<Dictionary<int, IEnumerable<string>>> GetDraftBillsByCase(params int[] caseIds)
        {
            var settings = await _billingSiteSettingsResolver.Resolve(new BillingSiteSettingsScope {Scope = SettingsResolverScope.WithoutUserSpecificSettings});

            if (!settings.ShouldWarnIfDraftBillForSameCaseExist) return new Dictionary<int, IEnumerable<string>>();

            var billedItems = from bi in _dbContext.Set<BilledItem>()
                              join wip in _dbContext.Set<WorkInProgress>() on
                                  new
                                  {
                                      WipEntityNo = bi.WipEntityId,
                                      WipTransNo = bi.WipTransactionId,
                                      WipSeqNo = bi.WipSequenceNo
                                  }
                                  equals new
                                  {
                                      WipEntityNo = wip.EntityId,
                                      WipTransNo = wip.TransactionId,
                                      WipSeqNo = wip.WipSequenceNo
                                  }
                                  into wip1
                              from wip in wip1
                              where wip.CaseId != null && caseIds.Contains((int) wip.CaseId)
                              select new
                              {
                                  EntityNo = bi.EntityId,
                                  TransNo = bi.TransactionId,
                                  CaseId = (int) wip.CaseId
                              };

            var openItems = from o in _dbContext.Set<OpenItem>()
                            join bi in billedItems on
                                new
                                {
                                    o.ItemEntityId,
                                    o.ItemTransactionId
                                }
                                equals new
                                {
                                    ItemEntityId = bi.EntityNo,
                                    ItemTransactionId = bi.TransNo
                                }
                                into bi1
                            from bi in bi1
                            where o.Status == (int) TransactionStatus.Draft
                                  && (o.TypeId == ItemType.DebitNote || o.TypeId == ItemType.InternalDebitNote)
                            select new
                            {
                                bi.CaseId,
                                o.OpenItemNo
                            };

            return await (from o in openItems
                          group o by o.CaseId
                          into o1
                          select new
                          {
                              CaseId = o1.Key,
                              OpenItems = o1.Select(_ => _.OpenItemNo).Distinct()
                          }).ToDictionaryAsync(k => k.CaseId, v => v.OpenItems);
        }

        public async Task<Dictionary<int, decimal?>> GetTotalAvailableWip(int[] caseIds, int? entityId)
        {
            var interEntityBilling = await GetInterEntityBillingSetting();

            return await (from wip in _dbContext.Set<WorkInProgress>()
                          where wip.Status != (short) TransactionStatus.Draft
                                && (interEntityBilling || wip.EntityId == entityId)
                                && wip.CaseId != null && caseIds.Contains((int) wip.CaseId)
                          group wip by wip.CaseId
                          into g1
                          select new
                          {
                              CaseId = (int) g1.Key,
                              WipBalance = g1.DefaultIfEmpty().Sum(_ => _.Balance)
                          }).ToDictionaryAsync(k => k.CaseId, v => v.WipBalance);
        }

        async Task<bool> GetInterEntityBillingSetting()
        {
            var settings = await _billingSiteSettingsResolver.Resolve(new BillingSiteSettingsScope {Scope = SettingsResolverScope.WithoutUserSpecificSettings});
            return settings.InterEntityBilling;
        }
    }
}