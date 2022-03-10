using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Components.Core;
using TransactionStatus = InprotechKaizen.Model.Accounting.TransactionStatus;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public interface IOpenItemService
    {
        Task<OpenItemModel> PrepareForNewDraftBill(int userIdentityId, string culture, ItemTypesForBilling itemType);
        Task<OpenItemModel> RetrieveForExistingBill(int userIdentityId, string culture, int itemEntityId, string openItemNo);
        Task<OpenItemModel> MergeSelectedDraftDebitNotes(int userIdentityId, string culture, string openItemNos);
        Task<ValidationErrorCollection> ValidateItemDate(DateTime date);
        Task<bool> ValidateOpenItemNoIsUnique(string openItemNo);
        Task<IEnumerable<FinaliseValidationSummary>> ValidateBeforeFinalise(FinaliseRequest request);
        Task<SaveOpenItemResult> SaveNewDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId);
        Task<SaveOpenItemResult> UpdateDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId);
        Task<SaveOpenItemResult> FinaliseDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId, BillGenerationTracking settings, bool shouldSendBillsToReviewer);
        Task<bool> DeleteDraftBill(int userIdentityId, string culture, int itemEntityId, string openItemNo);
        Task PrintBills(int userIdentityId, string culture, IEnumerable<BillGenerationRequest> bills, BillGenerationTracking trackingDetails, bool shouldSendBillsToReviewer);
        Task GenerateCreditBill(int userIdentityId, string culture, IEnumerable<BillGenerationRequest> bills, BillGenerationTracking trackingDetails);
    }

    public class OpenItemService : IOpenItemService
    {
        readonly IGetOpenItemCommand _getOpenItemCommand;
        readonly ICaseStatusValidator _caseStatusValidator;
        readonly IValidateTransactionDates _validateTransactionDate;
        readonly IDraftBillManagementCommands _deleteBillCoammnd;
        readonly IFinaliseBillValidator _finaliseBillValidator;
        readonly IDebtorRestriction _debtorRestriction;
        readonly IWipItemsService _wipItemsService;
        readonly IOrchestrator _orchestrator;
        readonly IEntities _entities;
        readonly Func<DateTime> _now;

        public OpenItemService(
                         IGetOpenItemCommand getOpenItemCommand, 
                         ICaseStatusValidator caseStatusValidator,
                         IValidateTransactionDates validateTransactionDate, 
                         IDraftBillManagementCommands deleteBillCoammnd,
                         IFinaliseBillValidator finaliseBillValidator,
                         IDebtorRestriction debtorRestriction,
                         IWipItemsService wipItemsService,
                         IOrchestrator orchestrator,
                         IEntities entities,
                         Func<DateTime> now)
        {
            _getOpenItemCommand = getOpenItemCommand;
            _caseStatusValidator = caseStatusValidator;
            _validateTransactionDate = validateTransactionDate;
            _deleteBillCoammnd = deleteBillCoammnd;
            _finaliseBillValidator = finaliseBillValidator;
            _debtorRestriction = debtorRestriction;
            _wipItemsService = wipItemsService;
            _orchestrator = orchestrator;
            _entities = entities;
            _now = now;
        }

        public async Task<OpenItemModel> PrepareForNewDraftBill(int userIdentityId, string culture, ItemTypesForBilling itemType)
        {
            return await _getOpenItemCommand.GetOpenItemDefaultForItemType(userIdentityId, culture, (int) itemType);
        }

        public async Task<OpenItemModel> RetrieveForExistingBill(int userIdentityId, string culture, int itemEntityId, string openItemNo)
        {
            var openItem = await _getOpenItemCommand.GetOpenItem(userIdentityId, culture, itemEntityId, openItemNo);

            if (openItem.IsCredit())
            {
                ReverseSignsForCreditNote(openItem);
            }

            return openItem;
        }

        public async Task<OpenItemModel> MergeSelectedDraftDebitNotes(int userIdentityId, string culture, string openItemNos)
        {
            if (openItemNos == null) throw new ArgumentNullException(nameof(openItemNos));
            if (openItemNos.Split(new[] {'|'}, StringSplitOptions.RemoveEmptyEntries).Length <= 1) throw new ArgumentException("There must be more than 1 debit notes to be drafted");

            var openItems = (await _getOpenItemCommand.GetOpenItems(userIdentityId, culture, openItemNos)).ToArray();

            if (!openItems.Any()) return new OpenItemModel();

            var r = ReturnDetailsFromFirstOpenItem(openItems);

            var keys = new MergeXmlKeys();
            var statementRef = new StringBuilder();
            var referenceText = new StringBuilder();
            var scope = new StringBuilder();
            var regarding = new StringBuilder();

            foreach (var openItem in openItems)
            {
                SumValues(r.Item, openItem, r.AllCurrencySame);

                keys.OpenItemXmls.Add(new OpenItemXmlKey
                {
                    ItemEntityNo = openItem.ItemEntityId.GetValueOrDefault(),
                    ItemTransNo = openItem.ItemTransactionId.GetValueOrDefault()
                });

                ConcatenateRefText(referenceText, openItem.ReferenceText);
                ConcatenateRefText(scope, openItem.Scope);
                ConcatenateRefText(regarding, openItem.Regarding);
                ConcatenateRefText(statementRef, openItem.StatementRef);
            }

            r.Item.MergedItemKeysInXml = keys.ToString();
            r.Item.ReferenceText = referenceText.ToString();
            r.Item.Scope = scope.ToString();
            r.Item.Regarding = regarding.ToString();
            r.Item.StatementRef = statementRef.ToString();

            return r.Item;
        }

        public async Task<ValidationErrorCollection> ValidateItemDate(DateTime date)
        {
            var result = await _validateTransactionDate.For(date);
            if (result.isValid)
            {
                return new ValidationErrorCollection();
            }

            return new ValidationErrorCollection
            {
                ValidationErrorList = new List<ValidationError>
                {
                    new()
                    {
                        WarningCode = result.isWarningOnly ? result.code : string.Empty,
                        WarningDescription = result.isWarningOnly ? KnownErrors.CodeMap[result.code] : string.Empty,
                        ErrorCode = !result.isWarningOnly ? result.code : string.Empty,
                        ErrorDescription = !result.isWarningOnly ? KnownErrors.CodeMap[result.code] : string.Empty
                    }
                }
            };
        }
        
        public async Task<bool> ValidateOpenItemNoIsUnique(string openItemNo)
        {
            return await _getOpenItemCommand.IsOpenItemNoUnique(openItemNo);
        }

        public async Task<IEnumerable<FinaliseValidationSummary>> ValidateBeforeFinalise(FinaliseRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            return await _finaliseBillValidator.Validate(request);
        }

        public async Task<SaveOpenItemResult> SaveNewDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null) throw new ArgumentException(nameof(model.ItemEntityId));

            if (await _entities.IsRestrictedByCurrency((int)model.ItemEntityId))
            {
                const string errorCode = KnownErrors.EntityRestrictedByCurrency;
                return new SaveOpenItemResult(errorCode, KnownErrors.CodeMap[errorCode]);
            }

            if (await _caseStatusValidator.GetCasesRestrictedForBilling(model.AvailableWipItems.DistinctCaseIds().ToArray()).AnyAsync())
            {
                const string errorCode = KnownErrors.BillCaseHasStatusRestrictedForBilling;
                return new SaveOpenItemResult(errorCode, KnownErrors.CodeMap[errorCode]);
            }

            if (model.DebitOrCreditNotes.Any(_ => _.LocalValue < 0))
            {
                const string errorCode = KnownErrors.TotalOfDebitOrCreditNoteMustBeGreaterThanZero;
                return new SaveOpenItemResult(errorCode, KnownErrors.CodeMap[errorCode]);
            }

            if (await _debtorRestriction.HasDebtorsNotConfiguredForBilling(model.DebitOrCreditNotes.Select(_ => _.DebtorNameId).ToArray()))
            {
                const string errorCode = KnownErrors.DebtorNotAClientOrNotConfiguredForBilling;
                return new SaveOpenItemResult(errorCode, KnownErrors.CodeMap[errorCode]);
            }

            if (model.IsCredit()) ReverseSignsForCreditNote(model);
            
            return await _orchestrator.SaveNewDraftBill(userIdentityId, culture, model, requestId);
        }

        public async Task<SaveOpenItemResult> UpdateDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null) throw new ArgumentException(nameof(model.ItemEntityId));

            if (await _entities.IsRestrictedByCurrency((int)model.ItemEntityId))
            {
                const string errorCode = KnownErrors.EntityRestrictedByCurrency;
                return new SaveOpenItemResult(errorCode, KnownErrors.CodeMap[errorCode]);
            }

            if (await _caseStatusValidator.GetCasesRestrictedForBilling(model.AvailableWipItems.DistinctCaseIds().ToArray()).AnyAsync())
            {
                const string errorCode = KnownErrors.BillCaseHasStatusRestrictedForBilling;
                return new SaveOpenItemResult(errorCode, KnownErrors.CodeMap[errorCode]);
            }

            if (model.DebitOrCreditNotes.Any(_ => _.LocalValue < 0))
            {
                const string errorCode = KnownErrors.TotalOfDebitOrCreditNoteMustBeGreaterThanZero;
                return new SaveOpenItemResult(errorCode, KnownErrors.CodeMap[errorCode]);
            }

            if (await _debtorRestriction.HasDebtorsNotConfiguredForBilling(model.DebitOrCreditNotes.Select(_ => _.DebtorNameId).ToArray()))
            {
                const string errorCode = KnownErrors.DebtorNotAClientOrNotConfiguredForBilling;
                return new SaveOpenItemResult(errorCode, KnownErrors.CodeMap[errorCode]);
            }

            if (model.IsCredit()) ReverseSignsForCreditNote(model);

            return await _orchestrator.UpdateDraftBill(userIdentityId, culture, model, requestId);
        }

        public async Task<SaveOpenItemResult> FinaliseDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId, BillGenerationTracking settings, bool shouldSendBillsToReviewer)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (model.ItemEntityId == null) throw new ArgumentException(nameof(model.ItemEntityId));
            if (model.ItemTransactionId == null) throw new ArgumentException(nameof(model.ItemTransactionId));
            
            var distinctCaseIdsIncludedInBill = model.AvailableWipItems.DistinctCaseIds().ToArray();
            if (model.AvailableWipItems.Any())
            {
                distinctCaseIdsIncludedInBill = (await _wipItemsService.GetAvailableWipItems(userIdentityId, culture, new WipSelectionCriteria
                {
                    ItemEntityId = (int)model.ItemEntityId,
                    ItemTransactionId = (int)model.ItemTransactionId,
                    ItemDate = model.ItemDate,
                    ItemType = (ItemType)model.ItemType
                })).DistinctCaseIds().ToArray();
            }

            if (await _caseStatusValidator.GetCasesRestrictedForBilling(distinctCaseIdsIncludedInBill).AnyAsync())
            {
                var errorCode = KnownErrors.BillCaseHasStatusRestrictedForBilling;
                return new SaveOpenItemResult(errorCode, KnownErrors.CodeMap[errorCode]);
            }

            return await _orchestrator.FinaliseDraftBill(userIdentityId, culture, model, requestId, settings, shouldSendBillsToReviewer);
        }

        public async Task<bool> DeleteDraftBill(int userIdentityId, string culture, int itemEntityId, string openItemNo)
        {
            if (openItemNo == null) throw new ArgumentNullException(nameof(openItemNo));

            await _deleteBillCoammnd.Delete(userIdentityId, culture, itemEntityId, openItemNo);

            return true;
        }

        public async Task GenerateCreditBill(int userIdentityId, string culture, IEnumerable<BillGenerationRequest> bills, BillGenerationTracking trackingDetails)
        {
            if (bills == null) throw new ArgumentNullException(nameof(bills));
            
            await _orchestrator.GenerateCreditBill(userIdentityId, culture, bills, trackingDetails);
        }

        public async Task PrintBills(int userIdentityId, string culture, IEnumerable<BillGenerationRequest> bills, BillGenerationTracking trackingDetails, bool shouldSendBillsToReviewer)
        {
            if (bills == null) throw new ArgumentNullException(nameof(bills));
            
            await _orchestrator.PrintBills(userIdentityId, culture, bills, trackingDetails, shouldSendBillsToReviewer);
        }
        
        static void ConcatenateRefText(StringBuilder str, string text)
        {
            if (string.IsNullOrEmpty(text)) return;
            if (str.Length > 0)
            {
                str.AppendLine();
            }

            str.Append(text);
        }

        static void SumValues(OpenItemModel returnOpenItem, OpenItemModel currentOpenItem, bool allCurrencySame)
        {
            returnOpenItem.ItemPreTaxValue = Sum(returnOpenItem.ItemPreTaxValue, currentOpenItem.ItemPreTaxValue).GetValueOrDefault();
            returnOpenItem.LocalTaxAmount = Sum(returnOpenItem.LocalTaxAmount, currentOpenItem.LocalTaxAmount).GetValueOrDefault();
            returnOpenItem.WriteDown = Sum(returnOpenItem.WriteDown, currentOpenItem.WriteDown).GetValueOrDefault();
            returnOpenItem.WriteUp = Sum(returnOpenItem.WriteUp, currentOpenItem.WriteUp).GetValueOrDefault();
            returnOpenItem.LocalOriginalTakenUp = Sum(returnOpenItem.LocalOriginalTakenUp, currentOpenItem.LocalOriginalTakenUp);

            if (allCurrencySame)
            {
                returnOpenItem.ForeignTaxAmount = Sum(returnOpenItem.ForeignTaxAmount, currentOpenItem.ForeignTaxAmount);
                returnOpenItem.ForeignOriginalTakenUp = Sum(returnOpenItem.ForeignOriginalTakenUp, currentOpenItem.ForeignOriginalTakenUp);
                returnOpenItem.ForeignValue = Sum(returnOpenItem.ForeignValue, currentOpenItem.ForeignValue);
                returnOpenItem.ForeignBalance = Sum(returnOpenItem.ForeignBalance, currentOpenItem.ForeignBalance);
            }
            else
            {
                returnOpenItem.ForeignTaxAmount = null;
                returnOpenItem.ForeignOriginalTakenUp = null;
                returnOpenItem.ForeignValue = null;
                returnOpenItem.ForeignBalance = null;
            }

            returnOpenItem.BillTotal = Sum(returnOpenItem.BillTotal, currentOpenItem.BillTotal).GetValueOrDefault();
        }

        (OpenItemModel Item, string Currency, bool AllCurrencySame) ReturnDetailsFromFirstOpenItem(OpenItemModel[] openItems)
        {
            var item = new OpenItemModel();
            var firstOpenItem = openItems.First();
            item.ItemEntityId = firstOpenItem.ItemEntityId;
            item.AccountEntityId = firstOpenItem.AccountEntityId;
            item.ItemDate = _now().Date;
            item.Status = (short) TransactionStatus.Draft;
            item.StaffName = firstOpenItem.StaffName;
            item.StaffId = firstOpenItem.StaffId;
            item.StaffProfitCentre = firstOpenItem.StaffProfitCentre;
            item.ShouldUseRenewalDebtor = false;
            item.CanUseRenewalDebtor = firstOpenItem.CanUseRenewalDebtor;
            item.LocalCurrencyCode = firstOpenItem.LocalCurrencyCode;
            item.LocalDecimalPlaces = firstOpenItem.LocalDecimalPlaces;
            item.IsWriteDownWip = false;
            item.ItemType = firstOpenItem.ItemType;
            item.ItemTypeDescription = firstOpenItem.ItemTypeDescription;
            item.BillFormatId = firstOpenItem.BillFormatId;
            item.OpenItemXml = firstOpenItem.OpenItemXml;
            item.LanguageId = firstOpenItem.LanguageId;
            item.LanguageDescription = firstOpenItem.LanguageDescription;

            var allCurrencySame = openItems.All(_ => _.Currency == firstOpenItem.Currency);
            if (allCurrencySame)
            {
                item.Currency = firstOpenItem.Currency;
            }

            return (item, firstOpenItem.Currency, allCurrencySame);
        }

        static decimal? Sum(decimal? val1, decimal? val2)
        {
            return val1.GetValueOrDefault() + val2.GetValueOrDefault();
        }

        static void ReverseSignsForCreditNote(OpenItemModel openItemModel)
        {
            openItemModel.LocalValue *= -1;
            openItemModel.LocalBalance *= -1;
            openItemModel.LocalTaxAmount *= -1;
            openItemModel.ItemPreTaxValue *= -1;
            openItemModel.BillTotal *= -1;
            openItemModel.ForeignValue *= -1;
            openItemModel.ForeignBalance *= -1;
            openItemModel.ForeignTaxAmount *= -1;
            openItemModel.ExchangeRateVariance *= -1;

            foreach (var billLine in openItemModel.BillLines)
                billLine.ReverseSigns();
            
            foreach (var creditNote in openItemModel.DebitOrCreditNotes)
                creditNote.ReverseSigns();
            
            foreach (var wipItem in openItemModel.AvailableWipItems)
                wipItem.ReverseSignsForCreditNote();
        }
    }
}