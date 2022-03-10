using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Delivery
{
    public interface IFinalisedBillDetailsResolver
    {
        Task<(ItemType ItemType, DateTime? ItemDate, int DebtorId, Dictionary<int, string> Cases, bool IsRenewalDebtor)> Resolve(BillGenerationRequest request);
    }

    public class FinalisedBillDetailsResolver : IFinalisedBillDetailsResolver
    {
        readonly IDbContext _dbContext;
        readonly Dictionary<(int, string), (ItemType, DateTime?, int, Dictionary<int, string>, bool)> _billDetailsCache = new();

        public FinalisedBillDetailsResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<(ItemType ItemType, DateTime? ItemDate, int DebtorId, Dictionary<int, string> Cases, bool IsRenewalDebtor)> Resolve(BillGenerationRequest request)
        {
            if (!_billDetailsCache.TryGetValue((request.ItemEntityId, request.OpenItemNo), out var details))
            {
                var interim = await (from o in _dbContext.Set<OpenItem>()
                                     join wh in _dbContext.Set<WorkHistory>() on
                                         new
                                         {
                                             ItemEntityId = (int?)o.ItemEntityId,
                                             ItemTransactionId = (int?)o.ItemTransactionId
                                         }
                                         equals new
                                         {
                                             ItemEntityId = wh.RefEntityId,
                                             ItemTransactionId = wh.RefTransactionId
                                         }
                                         into wh1
                                     from wh in wh1.DefaultIfEmpty()
                                     where o.ItemEntityId == request.ItemEntityId
                                           && o.OpenItemNo == request.OpenItemNo
                                     select new
                                     {
                                         o.TypeId,
                                         o.ItemDate,
                                         DebtorId = o.AccountDebtorId,
                                         o.MainCaseId,
                                         IsRenewalDebtor = o.IsRenewalDebtor == 1,
                                         CaseId = wh != null && wh.CaseId != null ? wh.CaseId : null
                                     }).ToArrayAsync();

                var common = interim.ElementAt(0);

                var itemType = common.TypeId;
                var itemDate = common.ItemDate;
                var debtorId = common.DebtorId;
                var isRenewalDebtor = common.IsRenewalDebtor;

                var caseIdsDistinct = GetCaseIds(interim).Distinct();

                var casesIncludedInBill = await _dbContext.Set<Case>().Where(_ => caseIdsDistinct.Contains(_.Id))
                                                          .ToDictionaryAsync(k => k.Id, v => v.Irn);

                details = (itemType, itemDate, debtorId, casesIncludedInBill, isRenewalDebtor);

                _billDetailsCache.Add((request.ItemEntityId, request.OpenItemNo), details);
            }

            return details;
        }

        IEnumerable<int> GetCaseIds(IEnumerable<dynamic> interimResults)
        {
            foreach (var interim in interimResults)
            {
                if (interim.CaseId != null) yield return (int)interim.CaseId;
                if (interim.MainCaseId != null) yield return (int)interim.MainCaseId;
            }
        }
    }
}
