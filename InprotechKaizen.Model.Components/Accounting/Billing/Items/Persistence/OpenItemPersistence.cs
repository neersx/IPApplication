using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class OpenItemPersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly IDbContext _dbContext;
        readonly IOpenItemNumbers _openItemNumbers;
        readonly IExactNameAddressSnapshot _exactNameAddressSnapshot;
        readonly ISiteControlReader _siteControlReader;
        readonly ILogger<OpenItemPersistence> _logger;

        public OpenItemPersistence(IDbContext dbContext,
                                   IOpenItemNumbers openItemNumbers,
                                   IExactNameAddressSnapshot exactNameAddressSnapshot,
                                   ISiteControlReader siteControlReader,
                                   ILogger<OpenItemPersistence> logger)
        {
            _dbContext = dbContext;
            _openItemNumbers = openItemNumbers;
            _exactNameAddressSnapshot = exactNameAddressSnapshot;
            _siteControlReader = siteControlReader;
            _logger = logger;
        }

        public Stage Stage => Stage.SaveOpenItem;
        
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
                await InsertOrUpdateAccount((int)model.AccountEntityId, 
                                            debitOrCreditNote.DebtorNameId);

                var r = await InsertOpenItem(
                                             (int)model.ItemEntityId,
                                             (int)model.ItemTransactionId,
                                             (int)model.AccountEntityId,
                                             model,
                                             debitOrCreditNote);

                result.DebtorOpenItemNos.Add(r);
            }

            return !result.HasError;
        }

        async Task<DebtorOpenItemNo> InsertOpenItem(int itemEntityId, int itemTransactionId, int accountEntityId, OpenItemModel model, DebitOrCreditNote debitOrCreditNote)
        {
            var debtorId = debitOrCreditNote.DebtorNameId;
            var debtorNameType = debitOrCreditNote.DebtorNameType;
            var hasCurrencyCode = !string.IsNullOrWhiteSpace(model.Currency);
            var isRenewalDebtor = debitOrCreditNote.DebtorNameType == KnownNameTypes.RenewalsDebtor || model.ShouldUseRenewalDebtor;
            var debtor = model.Debtors.Single(_ => _.NameId == debtorId && _.NameType == debtorNameType);
            var referenceText = model.ReferenceText.SplitByLength();
            var regarding = model.Regarding.SplitByLength();
            
            var localTax = debitOrCreditNote.Taxes.Sum(_ => Math.Round(_.TaxAmount, 2));

            var itemDueDate = await ResolveItemDueDate(debtorId, (ItemType)model.ItemType, model.ItemDate, model.ItemDueDate);

            var openItemNo = await ResolveOpenItemNo(itemEntityId, model.StaffId, debitOrCreditNote.DebtorNameId, debitOrCreditNote.OpenItemNo, debitOrCreditNote.EnteredOpenItemNo);

            var snapshotId = await ResolveNameAddressSnapshotId(debtor, model.NameSnapNo);

            var openItem = _dbContext.Set<OpenItem>()
                                     .Add(new OpenItem
                                     {
                                         ItemEntityId = itemEntityId,
                                         ItemTransactionId = itemTransactionId,
                                         AccountEntityId = accountEntityId,
                                         AccountDebtorId = debitOrCreditNote.DebtorNameId,
                                         OpenItemNo = openItemNo,
                                         ActionId = model.Action.NullIfEmptyOrWhitespace(),
                                         ItemDate = model.ItemDate,
                                         PostDate = model.PostDate,
                                         PostPeriodId = model.PostPeriodId,
                                         ClosePostDate = model.ClosePostDate,
                                         ClosePostPeriodId = model.ClosePostPeriodId,
                                         Status = (TransactionStatus)model.Status,
                                         TypeId = (ItemType)model.ItemType,
                                         BillPercentage = debitOrCreditNote.BillPercentage,
                                         StaffId = model.StaffId,
                                         StaffProfitCentre = model.StaffProfitCentre,
                                         Currency = model.Currency.NullIfEmptyOrWhitespace(),
                                         ExchangeRate = hasCurrencyCode ? model.ExchangeRate : null,
                                         PreTaxValue = debitOrCreditNote.LocalValue - localTax,
                                         LocalTaxAmount = localTax,
                                         LocalValue = debitOrCreditNote.LocalValue,
                                         ForeignTaxAmount = hasCurrencyCode ? debitOrCreditNote.ForeignTaxAmount : null,
                                         ForeignValue = hasCurrencyCode ? debitOrCreditNote.ForeignValue : null,
                                         LocalBalance = debitOrCreditNote.LocalBalance,
                                         ForeignBalance = hasCurrencyCode ? debitOrCreditNote.ForeignBalance : null,
                                         ExchangeRateVariance = hasCurrencyCode ? debitOrCreditNote.ExchangeRateVariance : null,
                                         StatementRef = model.StatementRef.NullIfEmptyOrWhitespace(),
                                         ReferenceText = referenceText.ShortText,
                                         LongReferenceText = referenceText.LongText,
                                         NameSnapshotId = snapshotId,
                                         BillFormatId = model.BillFormatId,
                                         IsBillPrinted = model.HasBillBeenPrinted ? 1 : 0,
                                         Regarding = regarding.ShortText,
                                         LongRegarding = regarding.LongText,
                                         Scope = model.Scope.NullIfEmptyOrWhitespace(),
                                         LanguageId = model.LanguageId,
                                         AssociatedOpenItemNo = model.AssociatedOpenItemNo.NullIfEmptyOrWhitespace(),
                                         ImageId = model.ImageId,
                                         ForeignEquivalentCurrency = model.ForeignEquivalentCurrency,
                                         ForeignEquivalentExchangeRate = model.ForeignEquivalentExchangeRate,
                                         ItemDueDate = itemDueDate,
                                         PenaltyInterest = model.PenaltyInterest,
                                         LocalOriginalTakenUp = model.LocalOriginalTakenUp,
                                         ForeignOriginalTakenUp = hasCurrencyCode && model.ForeignOriginalTakenUp != 0 ? model.ForeignOriginalTakenUp : null,
                                         IncludeOnlyWip = model.IncludeOnlyWip,
                                         PayForWip = model.PayForWip,
                                         PayPropertyType = model.PayPropertyType,
                                         IsRenewalDebtor = isRenewalDebtor ? 1 : 0,
                                         CaseProfitCentre = model.CaseProfitCentre.NullIfEmptyOrWhitespace(),
                                         LockIdentityId = model.LockIdentityId,
                                         MainCaseId = model.MainCaseId
                                     });

            await _dbContext.SaveChangesAsync();

            _logger.Trace($"{nameof(InsertOpenItem)} Added={openItem.OpenItemNo}", openItem);

            return new DebtorOpenItemNo(debitOrCreditNote.DebtorNameId)
            {
                OpenItemNo = openItem.OpenItemNo,
                LogDateTimeStamp = openItem.LogDateTimeStamp
            };
        }

        async Task<int> ResolveNameAddressSnapshotId(DebtorData debtor, int? existingSnapshotId)
        {
            var snapshotId = await _exactNameAddressSnapshot.Derive(new NameAddressSnapshotParameter
            {
                AccountDebtorId = debtor.NameId,
                FormattedName = debtor.FormattedName,
                AddressId = debtor.AddressId,
                FormattedAddress = debtor.Address,
                AttentionNameId = debtor.AttentionNameId,
                FormattedAttention = debtor.AttentionName,
                AddressChangeReasonId = debtor.AddressChangeReasonId,
                FormattedReference = debtor.HasReferenceNoChanged ? debtor.ReferenceNo : null,
                SnapshotId = existingSnapshotId
            });

            if (snapshotId != existingSnapshotId)
            {
                _logger.Trace($"{nameof(ResolveNameAddressSnapshotId)} acquired NameSnapshotId={snapshotId} [debtorId={debtor.NameId}/{debtor.NameType}]");
            }

            return snapshotId;
        }

        async Task<DateTime?> ResolveItemDueDate(int debtorId, ItemType itemType, DateTime itemDate, DateTime? itemDueDate)
        {
            if (itemType != ItemType.DebitNote && itemType != ItemType.InternalDebitNote) return itemDueDate;

            var calculatedTradingTerms = await (from s in _dbContext.Set<ClientDetail>()
                                                where s.Id == debtorId
                                                select s.TradingTerms)
                .SingleOrDefaultAsync() ?? _siteControlReader.Read<int>(SiteControls.TradingTerms);

            return itemDate + TimeSpan.FromDays(calculatedTradingTerms);
        }

        async Task<string> ResolveOpenItemNo(int itemEntityId, int staffId, int debtorId, string openItemNo, string enteredOpenItemNo)
        {
            var candidateOpenItemNo = openItemNo;

            if (string.IsNullOrWhiteSpace(openItemNo) && string.IsNullOrWhiteSpace(enteredOpenItemNo))
            {
                candidateOpenItemNo = await _openItemNumbers.AcquireNextDraftNumber(itemEntityId, staffId);

                _logger.Trace($"{nameof(ResolveOpenItemNo)} acquired OpenItemNo={candidateOpenItemNo} [itemEntityId={itemEntityId}/staffId={staffId}/debtorId={debtorId}]");
            }
            else if (!string.IsNullOrWhiteSpace(enteredOpenItemNo))
            {
                candidateOpenItemNo = enteredOpenItemNo;

                _logger.Trace($"{nameof(ResolveOpenItemNo)} use EnteredOpenItemNo={candidateOpenItemNo} [debtorId={debtorId}]");
            }

            return candidateOpenItemNo;
        }
        
        async Task InsertOrUpdateAccount(int accountEntityId, int debtorId)
        {
            var account = await _dbContext.Set<Account>()
                                          .SingleOrDefaultAsync(_ => _.EntityId == accountEntityId &&
                                                                     _.NameId == debtorId) ??
                          _dbContext.Set<Account>().Add(new Account
                          {
                              EntityId = accountEntityId,
                              NameId = debtorId
                          });

            account.Balance = account.Balance.GetValueOrDefault() + 0;
            account.CreditBalance = account.CreditBalance.GetValueOrDefault() + 0;

            await _dbContext.SaveChangesAsync();
        }
    }
}
