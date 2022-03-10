using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class BillCreditsPersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly IDbContext _dbContext;
        readonly ILogger<BillCreditsPersistence> _logger;

        public BillCreditsPersistence(IDbContext dbContext, ILogger<BillCreditsPersistence> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }
        
        public Stage Stage => Stage.SaveBillCredits;

        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null || model.ItemTransactionId == null || model.AccountEntityId == null)
            {
                throw new ArgumentException($"{nameof(model.ItemEntityId)}, {nameof(model.ItemTransactionId)} and {nameof(model.AccountEntityId)} must all have a value.");
            }

            foreach (var debitOrCreditNote in model.DebitOrCreditNotes)
            {
                foreach (var creditItem in debitOrCreditNote.CreditItems.Where(_ => _.LocalSelected != 0))
                {
                    await AddBilledCredit((int)model.ItemEntityId,
                                          (int)model.ItemTransactionId,
                                          (int)model.AccountEntityId,
                                          debitOrCreditNote.DebtorNameId,
                                          creditItem);

                    var count = await LockOpenItemCase(creditItem);

                    if (count <= 0)
                    {
                        await LockOpenItem(creditItem);
                    }
                }
            }

            return true;
        }

        async Task AddBilledCredit(int itemEntityId, int itemTransactionId, int accountEntityId, int debtorId, CreditItem creditItem)
        {
            var billedCredit = _dbContext.Set<BilledCredit>().Add(new BilledCredit
            {
                DebitItemEntityId = itemEntityId,
                DebitItemTransactionId = itemTransactionId,
                DebitAccountEntityId = accountEntityId,
                DebitAccountDebtorId = debtorId,
                CreditItemEntityId = creditItem.ItemEntityId,
                CreditItemTransactionId = creditItem.ItemTransactionId,
                CreditAccountEntityId = creditItem.AccountEntityId,
                CreditAccountDebtorId = creditItem.AccountDebtorId,
                CreditCaseId = creditItem.CaseId,
                LocalSelected = creditItem.LocalSelected,
                ForeignSelected = creditItem.ForeignSelected,
                ForcedPayout = creditItem.IsForcedPayOut ? 1 : 0,
                SelectedRenewal = 0,
                SelectedNonRenewal = 0,
                CreditExchangeVariance = 0,
                CreditForcedPayout = 0
            });

            await _dbContext.SaveChangesAsync();

            _logger.Trace($"{nameof(AddBilledCredit)}", billedCredit);
        }

        async Task LockOpenItem(CreditItem creditItem)
        {
            var count = await _dbContext.UpdateAsync(_dbContext.Set<OpenItem>()
                                                   .Where(_ => _.ItemEntityId == creditItem.ItemEntityId &&
                                                               _.ItemTransactionId == creditItem.ItemTransactionId &&
                                                               _.AccountEntityId == creditItem.AccountEntityId &&
                                                               _.AccountDebtorId == creditItem.AccountDebtorId),
                                         _ => new OpenItem
                                         {
                                             Status = TransactionStatus.Locked
                                         });

            _logger.Trace($"{nameof(LockOpenItem)} # Locked: OpenItem={count} [entityId={creditItem.ItemEntityId}/transId={creditItem.ItemTransactionId}/acctEntityId={creditItem.AccountEntityId}/acctDebtorId={creditItem.AccountDebtorId}]");
        }

        async Task<int> LockOpenItemCase(CreditItem creditItem)
        {
            var count = await _dbContext.UpdateAsync(_dbContext.Set<OpenItemCase>()
                                                               .Where(_ => _.ItemEntityId == creditItem.ItemEntityId &&
                                                                           _.ItemTransactionId == creditItem.ItemTransactionId &&
                                                                           _.AccountEntityId == creditItem.AccountEntityId &&
                                                                           _.AccountDebtorId == creditItem.AccountDebtorId),
                                                     _ => new OpenItemCase
                                                     {
                                                         Status = TransactionStatus.Locked
                                                     });

            _logger.Trace($"{nameof(LockOpenItemCase)} # Locked: OpenItemCase={count} [entityId={creditItem.ItemEntityId}/transId={creditItem.ItemTransactionId}/acctEntityId={creditItem.AccountEntityId}/acctDebtorId={creditItem.AccountDebtorId}]");

            return count;
        }
    }
}
