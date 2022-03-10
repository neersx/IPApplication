using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class BilledItemsPersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly IDbContext _dbContext;
        readonly ILogger<BilledItemsPersistence> _logger;

        public BilledItemsPersistence(IDbContext dbContext, ILogger<BilledItemsPersistence> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public Stage Stage => Stage.SaveBilledItems;
        
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

            var itemIdentityId = (int)model.ItemEntityId;
            var itemTransactionId = (int)model.ItemTransactionId;

            foreach (var wipItem in model.AvailableWipItems)
            {
                MapBillLineToWip(model.BillLines, wipItem);

                ApplyWriteDownToDraftWip(model, wipItem);

                if (await IsWipItemIncludedInAnotherBill(model, wipItem))
                {
                    result.ErrorCode = KnownErrors.WipAlreadyOnDifferentBill;
                    result.ErrorDescription = KnownErrors.CodeMap[KnownErrors.WipAlreadyOnDifferentBill];

                    _logger.Warning($"{nameof(Run)} alert={result.ErrorCode} [{wipItem.EntityId}/{wipItem.TransactionId}/{wipItem.WipSeqNo}]");
                    break;
                }

                var accountEntityId = wipItem.CaseId != null ? model.AccountEntityId : null;

                await InsertOrUpdateAccount(accountEntityId, model.AccountDebtorNameId);

                await InsertBilledItem(itemIdentityId, itemTransactionId, accountEntityId, model.AccountDebtorNameId, wipItem);

                var w1 = await LockWipToDraftBill(wipItem);

                _logger.Trace($"{nameof(LockWipToDraftBill)} # Locked={w1} [{wipItem.EntityId}/{wipItem.TransactionId}/{wipItem.WipSeqNo}]");

                var d1 = await UpdateDraftWipBalancesOnDraftBill(wipItem);

                var d2 = await UpdateDraftWipBalancesOnDraftBillsWorkHistory(wipItem);

                if (d1 + d2 > 0)
                {
                    _logger.Trace($"UpdateDraftWipBalances # Updated: WipBalance={d1}, WorkHistoryBalance={d2} [{wipItem.EntityId}/{wipItem.TransactionId}/{wipItem.WipSeqNo}]");
                }
            }

            if (!result.HasError)
            {
                var d1 = await DeleteUnusedDraftWipItems(itemIdentityId, itemTransactionId);

                var d2 = await DeleteWorkHistoryForUnusedDraftWipItems(itemIdentityId, itemTransactionId);

                if (d1 + d2 > 0)
                {
                    _logger.Trace($"DeleteUnusedDraftWip+History # Deleted: DraftWipItems={d1}/WorkHistoryFromDraftWipItems={d2}");
                }
            }

            return !result.HasError;
        }

        async Task<int> DeleteUnusedDraftWipItems(int itemEntityId, int itemTransactionId)
        {
            return await _dbContext.DeleteAsync(from wip in _dbContext.Set<WorkInProgress>()
                                         join bi in _dbContext.Set<BilledItem>() on
                                             new
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
                                         from bi in bi1.DefaultIfEmpty()
                                         where wip.EntityId == itemEntityId &&
                                               wip.TransactionId == itemTransactionId &&
                                               bi == null
                                         select wip);
        }

        async Task<int> DeleteWorkHistoryForUnusedDraftWipItems(int itemEntityId, int itemTransactionId)
        {
            return await _dbContext.DeleteAsync(from wip in _dbContext.Set<WorkHistory>()
                                         join bi in _dbContext.Set<BilledItem>() on
                                             new
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
                                         from bi in bi1.DefaultIfEmpty()
                                         where wip.EntityId == itemEntityId &&
                                               wip.TransactionId == itemTransactionId &&
                                               bi == null
                                         select wip);
        }

        async Task<int> UpdateDraftWipBalancesOnDraftBillsWorkHistory(AvailableWipItem wipItem)
        {
            var workHistoryItemToUpdate = await (from bi in _dbContext.Set<BilledItem>()
                                                 join wh in _dbContext.Set<WorkHistory>() on
                                                     new
                                                     {
                                                         bi.WipEntityId,
                                                         bi.WipTransactionId,
                                                         bi.WipSequenceNo
                                                     }
                                                     equals new
                                                     {
                                                         WipEntityId = wh.EntityId,
                                                         WipTransactionId = wh.TransactionId,
                                                         wh.WipSequenceNo
                                                     }
                                                     into wh1
                                                 from wh in wh1
                                                 join wip in _dbContext.Set<WorkInProgress>() on
                                                     new
                                                     {
                                                         bi.WipEntityId,
                                                         bi.WipTransactionId,
                                                         bi.WipSequenceNo
                                                     }
                                                     equals new
                                                     {
                                                         WipEntityId = wip.EntityId,
                                                         WipTransactionId = wip.TransactionId,
                                                         wip.WipSequenceNo
                                                     }
                                                     into wip1
                                                 from wip in wip1
                                                 where wip.EntityId == wipItem.EntityId &&
                                                       wip.TransactionId == wipItem.TransactionId &&
                                                       wip.WipSequenceNo == wipItem.WipSeqNo &&
                                                       wip.Status == TransactionStatus.Draft
                                                 let localBilledValue = Math.Abs((decimal)(bi.BilledValue == null ? 0 : bi.BilledValue))
                                                 let foreignBilledValue = Math.Abs((decimal)(bi.ForeignBilledValue == null ? 0 : bi.ForeignBilledValue))
                                                 select new
                                                 {
                                                     wh.EntityId,
                                                     wh.TransactionId,
                                                     wh.WipSequenceNo,
                                                     LocalTransValue = wh.LocalValue < 0 ? localBilledValue * -1 : localBilledValue,
                                                     ForeignTransValue = wh.ForeignValue == null
                                                         ? (decimal?)null
                                                         : wh.ForeignValue < 0
                                                             ? foreignBilledValue * -1
                                                             : foreignBilledValue,
                                                     BillLineNo = wh.MovementClass == MovementClass.Billed ? bi.ItemLineNo : null
                                                 }).ToArrayAsync();

            var whUpdated = 0;

            foreach (var workHistoryItem in workHistoryItemToUpdate)
            {
                whUpdated += await _dbContext.UpdateAsync(from wh in _dbContext.Set<WorkHistory>()
                                                          where wh.EntityId == workHistoryItem.EntityId &&
                                                                wh.TransactionId == workHistoryItem.TransactionId &&
                                                                wh.WipSequenceNo == workHistoryItem.WipSequenceNo
                                                          select wh,
                                                          _ => new WorkHistory
                                                          {
                                                              LocalValue = workHistoryItem.LocalTransValue,
                                                              ForeignValue = workHistoryItem.ForeignTransValue,
                                                              BillLineNo = workHistoryItem.BillLineNo
                                                          });
            }

            return whUpdated;
        }

        async Task<int> UpdateDraftWipBalancesOnDraftBill(AvailableWipItem wipItem)
        {
            var wipItemsToUpdate = await (from bi in _dbContext.Set<BilledItem>()
                                          join wip in _dbContext.Set<WorkInProgress>() on
                                              new
                                              {
                                                  bi.WipEntityId,
                                                  bi.WipTransactionId,
                                                  bi.WipSequenceNo
                                              }
                                              equals new
                                              {
                                                  WipEntityId = wip.EntityId,
                                                  WipTransactionId = wip.TransactionId,
                                                  wip.WipSequenceNo
                                              }
                                              into wip1
                                          from wip in wip1
                                          where wip.EntityId == wipItem.EntityId &&
                                                wip.TransactionId == wipItem.TransactionId &&
                                                wip.WipSequenceNo == wipItem.WipSeqNo &&
                                                wip.Status == TransactionStatus.Draft
                                          let localBilledValue = Math.Abs((decimal)(bi.BilledValue == null ? 0 : bi.BilledValue))
                                          let foreignBilledValue = Math.Abs((decimal)(bi.ForeignBilledValue == null ? 0 : bi.ForeignBilledValue))
                                          select new
                                          {
                                              wip.EntityId,
                                              wip.TransactionId,
                                              wip.WipSequenceNo,
                                              LocalValue = wip.LocalValue < 0 ? localBilledValue * -1 : localBilledValue,
                                              LocalBalance = wip.Balance < 0 ? localBilledValue * -1 : localBilledValue,
                                              ForeignValue = wip.ForeignValue == null
                                                  ? (decimal?)null
                                                  : wip.ForeignValue < 0
                                                      ? foreignBilledValue * -1
                                                      : foreignBilledValue,
                                              ForeinBalance = wip.ForeignBalance == null
                                                  ? (decimal?)null
                                                  : wip.ForeignBalance < 0
                                                      ? foreignBilledValue * -1
                                                      : foreignBilledValue
                                          }).ToArrayAsync();

            var wipUpdated = 0;

            foreach (var wipItemToUpdate in wipItemsToUpdate)
            {
                wipUpdated += await _dbContext.UpdateAsync(from wip in _dbContext.Set<WorkInProgress>()
                                                           where wip.EntityId == wipItemToUpdate.EntityId &&
                                                                 wip.TransactionId == wipItemToUpdate.TransactionId &&
                                                                 wip.WipSequenceNo == wipItemToUpdate.WipSequenceNo
                                                           select wip,
                                                           _ => new WorkInProgress
                                                           {
                                                               LocalValue = wipItemToUpdate.LocalValue,
                                                               Balance = wipItemToUpdate.LocalBalance,
                                                               ForeignValue = wipItemToUpdate.ForeignValue,
                                                               ForeignBalance = wipItemToUpdate.ForeinBalance
                                                           });
            }

            return wipUpdated;
        }

        async Task<int> LockWipToDraftBill(AvailableWipItem wipItem)
        {
            return await _dbContext.UpdateAsync(from wip in _dbContext.Set<WorkInProgress>()
                                                where wip.EntityId == wipItem.EntityId &&
                                                      wip.TransactionId == wipItem.TransactionId &&
                                                      wip.WipSequenceNo == wipItem.WipSeqNo &&
                                                      wip.Status == TransactionStatus.Active
                                                select wip,
                                                _ => new WorkInProgress
                                                {
                                                    Status = TransactionStatus.Locked
                                                });
        }

        async Task InsertBilledItem(int itemEntityId, int itemTransactionId, int? accountEntityId, int accountDebtorId, AvailableWipItem wipItem)
        {
            var signModifier = wipItem.IsCreditWip.GetValueOrDefault() && wipItem.IsDraft ? -1 : 1;
            var billedValue = wipItem.LocalBilled * signModifier;
            var adjustedValue = wipItem.LocalVariation * signModifier;

            var hasForeignCurrency = !string.IsNullOrWhiteSpace(wipItem.ForeignCurrency);
            var foreignBilledValue = hasForeignCurrency ? wipItem.ForeignBilled * signModifier : null;
            var foreignAdjustedValue = hasForeignCurrency ? wipItem.ForeignVariation * signModifier : null;
            var generatedFromTaxCode = wipItem.GeneratedFromTaxCode.NullIfEmptyOrWhitespace();

            var billItem = _dbContext.Set<BilledItem>().Add(new BilledItem
            {
                EntityId = itemEntityId,
                TransactionId = itemTransactionId,
                WipEntityId = wipItem.EntityId,
                WipTransactionId = wipItem.TransactionId,
                WipSequenceNo = wipItem.WipSeqNo,
                BilledValue = billedValue,
                AdjustedValue = adjustedValue,
                ReasonCode = wipItem.ReasonCode,
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorId = accountDebtorId,
                ForeignCurrency = wipItem.ForeignCurrency,
                ForeignBilledValue = foreignBilledValue,
                ForeignAdjustedValue = foreignAdjustedValue,
                GeneratedFromTaxCode = generatedFromTaxCode
            });

            await _dbContext.SaveChangesAsync();

            _logger.Trace($"{nameof(InsertBilledItem)} Added [{wipItem.EntityId}/{wipItem.TransactionId}/{wipItem.WipSeqNo}]", billItem);
        }

        async Task InsertOrUpdateAccount(int? accountEntityId, int accountDebtorId)
        {
            if (accountEntityId != null)
            {
                var account = await _dbContext.Set<Account>()
                                              .SingleOrDefaultAsync(_ => _.EntityId == accountEntityId &&
                                                                         _.NameId == accountDebtorId) ??
                              _dbContext.Set<Account>().Add(new Account
                              {
                                  EntityId = (int)accountEntityId,
                                  NameId = accountDebtorId
                              });

                account.Balance = account.Balance.GetValueOrDefault() + 0;
                account.CreditBalance = account.CreditBalance.GetValueOrDefault() + 0;

                await _dbContext.SaveChangesAsync();
            }
        }

        async Task<bool> IsWipItemIncludedInAnotherBill(OpenItemModel model, AvailableWipItem wipItem)
        {
            return string.IsNullOrWhiteSpace(wipItem.GeneratedFromTaxCode) &&
                   !(model.ItemEntityId == wipItem.EntityId && model.ItemTransactionId == wipItem.TransactionId) &&
                   await _dbContext.Set<WorkInProgress>().AnyAsync(_ => _.EntityId == wipItem.EntityId &&
                                                                        _.TransactionId == wipItem.TransactionId &&
                                                                        _.WipSequenceNo == wipItem.WipSeqNo &&
                                                                        _.Status == TransactionStatus.Locked);
        }

        void ApplyWriteDownToDraftWip(OpenItemModel model, AvailableWipItem wipItem)
        {
            if (!wipItem.IsDraft || string.IsNullOrWhiteSpace(model.WriteDownReason)) return;

            wipItem.ReasonCode = model.WriteDownReason;
            wipItem.LocalVariation = wipItem.LocalBilled * -1;
            
            _logger.Trace($"{nameof(ApplyWriteDownToDraftWip)} set Reason={model.WriteDownReason} LocalVariation={wipItem.LocalVariation} [{wipItem.EntityId}/{wipItem.TransactionId}/{wipItem.WipSeqNo}]");
        }

        void MapBillLineToWip(IEnumerable<Presentation.BillLine> allBillLines, AvailableWipItem wipItem)
        {
            wipItem.BillLineNo = null;

            var lineNumber = (from bl in allBillLines
                            from blw in bl.WipItems
                            where wipItem.UniqueReferenceId == blw.UniqueReferenceId
                            select bl.ItemLineNo).ToArray();

            if (!lineNumber.Any()) return;
            
            wipItem.BillLineNo = lineNumber.First();

            _logger.Trace($"{nameof(MapBillLineToWip)} set LineNo={wipItem.BillLineNo} UniqueReferenceId={wipItem.UniqueReferenceId} [{wipItem.EntityId}/{wipItem.TransactionId}/{wipItem.WipSeqNo}]");
        }
    }
}
