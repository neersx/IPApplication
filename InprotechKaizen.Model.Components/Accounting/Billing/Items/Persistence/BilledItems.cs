using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Debtor;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Persistence;

using OpenItemXmlModel = InprotechKaizen.Model.Accounting.OpenItem.OpenItemXml;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public interface IBilledItems
    {
        Task Reinstate(int itemEntityId, int itemTransactionId, Guid requestId);
    }

    public class BilledItems : IBilledItems
    {
        readonly IDbContext _dbContext;
        readonly ILogger<BilledItems> _logger;

        public BilledItems(IDbContext dbContext, ILogger<BilledItems> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task Reinstate(int itemEntityId, int itemTransactionId, Guid requestId)
        {
            _logger.SetContext(requestId);

            var r1 = await ReinstateWipItems(itemEntityId, itemTransactionId);

            var r2 = await ReinstateCreditsOpenItem(itemEntityId, itemTransactionId);

            var r3 = await ReinstateCreditsOpenItemCase(itemEntityId, itemTransactionId);

            _logger.Trace($"{nameof(Reinstate)} # Unlocked: WipItems={r1}/CreditsOpenItem={r2}/CreditsOpenItemCase={r3}");

            var d1 = await DeleteBilledCredits(itemEntityId, itemTransactionId);

            var d2 = await DeleteBilledItems(itemEntityId, itemTransactionId);

            var d3 = await DeleteBillLines(itemEntityId, itemTransactionId);

            var d4 = await DeleteOpenItemTaxes(itemEntityId, itemTransactionId);

            var d5 = await DeleteDebtorHistories(itemEntityId, itemTransactionId);

            var d6 = await DeleteOpenItemXml(itemEntityId, itemTransactionId);

            var d7 = await DeleteOpenItemCopyTos(itemEntityId, itemTransactionId);

            var d8 = await DeleteOpenItems(itemEntityId, itemTransactionId);

            _logger.Trace($"{nameof(Reinstate)} # Deleted: BilledCredits={d1}/BilledItems={d2}/BillLines={d3}/OpenItemTax={d4}/DebtorHistory={d5}/OpenItemXml={d6}/OpenItemCopiesTo={d7}/OpenItem={d8}");
        }

        async Task<int> ReinstateWipItems(int entityId, int transactionId)
        {
            return await _dbContext.UpdateAsync(from wip in _dbContext.Set<WorkInProgress>()
                                                join bi in _dbContext.Set<BilledItem>() on new
                                                    {
                                                        WipEntityId = wip.EntityId,
                                                        WipTransactionId = wip.TransactionId,
                                                        wip.WipSequenceNo
                                                    }
                                                    equals new
                                                    {
                                                        bi.WipEntityId,
                                                        bi.WipTransactionId,
                                                        bi.WipSequenceNo
                                                    }
                                                    into bi1
                                                from bi in bi1
                                                where bi.EntityId == entityId &&
                                                      bi.TransactionId == transactionId &&
                                                      wip.Status == TransactionStatus.Locked
                                                select wip,
                                                _ => new WorkInProgress
                                                {
                                                    Status = TransactionStatus.Active
                                                });
        }

        async Task<int> ReinstateCreditsOpenItem(int entityId, int transactionId)
        {
            return await _dbContext.UpdateAsync(from oi in _dbContext.Set<OpenItem>()
                                                join bc in _dbContext.Set<BilledCredit>() on new
                                                    {
                                                        CreditItemEntityId = oi.ItemEntityId,
                                                        CreditItemTransactionId = oi.ItemTransactionId,
                                                        CreditAccountEntityId = oi.AccountEntityId,
                                                        CreditAccountDebtorId = oi.AccountDebtorId
                                                    }
                                                    equals new
                                                    {
                                                        bc.CreditItemEntityId,
                                                        bc.CreditItemTransactionId,
                                                        bc.CreditAccountEntityId,
                                                        bc.CreditAccountDebtorId
                                                    }
                                                    into bc1
                                                from bc in bc1
                                                where bc.DebitItemEntityId == entityId &&
                                                      bc.DebitItemTransactionId == transactionId
                                                select oi,
                                                _ => new OpenItem
                                                {
                                                    Status = TransactionStatus.Active,
                                                    LocalOriginalTakenUp = null,
                                                    ForeignOriginalTakenUp = null
                                                });
        }

        async Task<int> ReinstateCreditsOpenItemCase(int entityId, int transactionId)
        {
            return await _dbContext.UpdateAsync(from oic in _dbContext.Set<OpenItemCase>()
                                                join bc in _dbContext.Set<BilledCredit>() on new
                                                    {
                                                        CreditItemEntityId = oic.ItemEntityId,
                                                        CreditItemTransactionId = oic.ItemTransactionId,
                                                        CreditAccountEntityId = oic.AccountEntityId,
                                                        CreditAccountDebtorId = oic.AccountDebtorId,
                                                        CreditCaseId = (int?)oic.CaseId
                                                    }
                                                    equals new
                                                    {
                                                        bc.CreditItemEntityId,
                                                        bc.CreditItemTransactionId,
                                                        bc.CreditAccountEntityId,
                                                        bc.CreditAccountDebtorId,
                                                        bc.CreditCaseId
                                                    }
                                                    into bc1
                                                from bc in bc1
                                                where bc.DebitItemEntityId == entityId &&
                                                      bc.DebitItemTransactionId == transactionId
                                                select oic,
                                                _ => new OpenItemCase
                                                {
                                                    Status = TransactionStatus.Active
                                                });
        }

        async Task<int> DeleteBilledCredits(int entityId, int transactionId)
        {
            return await _dbContext.DeleteAsync(from bc in _dbContext.Set<BilledCredit>()
                                                where bc.DebitItemEntityId == entityId &&
                                                      bc.DebitItemTransactionId == transactionId
                                                select bc);
        }

        async Task<int> DeleteBilledItems(int entityId, int transactionId)
        {
            return await _dbContext.DeleteAsync(from bi in _dbContext.Set<BilledItem>()
                                                where bi.EntityId == entityId &&
                                                      bi.TransactionId == transactionId
                                                select bi);
        }

        async Task<int> DeleteBillLines(int entityId, int transactionId)
        {
            return await _dbContext.DeleteAsync(from bl in _dbContext.Set<BillLine>()
                                                where bl.ItemEntityId == entityId &&
                                                      bl.ItemTransactionId == transactionId
                                                select bl);
        }

        async Task<int> DeleteOpenItemTaxes(int entityId, int transactionId)
        {
            return await _dbContext.DeleteAsync(from oit in _dbContext.Set<OpenItemTax>()
                                                where oit.ItemEntityId == entityId &&
                                                      oit.ItemTransactionId == transactionId
                                                select oit);
        }

        async Task<int> DeleteDebtorHistories(int entityId, int transactionId)
        {
            return await _dbContext.DeleteAsync(from dh in _dbContext.Set<DebtorHistory>()
                                                where dh.ItemEntityId == entityId &&
                                                      dh.ItemTransactionId == transactionId
                                                select dh);
        }

        async Task<int> DeleteOpenItemXml(int entityId, int transactionId)
        {
            return await _dbContext.DeleteAsync(from oix in _dbContext.Set<OpenItemXmlModel>()
                                                where oix.ItemEntityId == entityId &&
                                                      oix.ItemTransactionId == transactionId
                                                select oix);
        }

        async Task<int> DeleteOpenItemCopyTos(int entityId, int transactionId)
        {
            return await _dbContext.DeleteAsync(from ct in _dbContext.Set<OpenItemCopyTo>()
                                                where ct.ItemEntityId == entityId &&
                                                      ct.ItemTransactionId == transactionId
                                                select ct);
        }

        async Task<int> DeleteOpenItems(int entityId, int transactionId)
        {
            return await _dbContext.DeleteAsync(from oi in _dbContext.Set<OpenItem>()
                                                where oi.ItemEntityId == entityId &&
                                                      oi.ItemTransactionId == transactionId
                                                select oi);
        }
    }
}
