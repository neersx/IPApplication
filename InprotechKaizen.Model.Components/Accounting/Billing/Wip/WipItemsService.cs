using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public interface IWipItemsService
    {
        Task<IEnumerable<AvailableWipItem>> GetAvailableWipItems(int userIdentityId, string culture, WipSelectionCriteria wipSelectionCriteria);

        Task<WipItemExchangeRates> GetWipItemExchangeRates(int userIdentityId, string culture, string currencyCode, WipSelectionCriteria wipSelectionCriteria);
        
        Task<IEnumerable<AvailableWipItem>> RecalculateDiscounts(int userIdentityId, string culture, decimal billedAmount, int raisedByStaffId, IEnumerable<AvailableWipItem> wipItems);

        Task<IEnumerable<AvailableWipItem>> ConvertDraftWipToAvailableWipItems(int userIdentityId, string culture, CompleteDraftWipItem[] draftWipItems, ItemType itemType, int staffId, string billCurrency, DateTime billDate, int? caseId, int debtorId);

        Task<IEnumerable<AvailableWipItem>> ConvertStampFeeWipToAvailableWipItems(int userIdentityId, string culture, 
                                                                                  DraftWip draftWipItem, int staffId, DateTime billDate);
    }

    public class WipItemsService : IWipItemsService
    {
        readonly ISiteControlReader _siteControlReader;
        readonly IAvailableWipItemCommands _availableWipItemCommands;
        readonly IExchangeDetailsResolver _exchangeDetailsResolver;
        readonly IDiscountsAndMargins _discountsAndMargins;
        readonly IDraftWipItem _draftWipItem;
        readonly Func<DateTime> _now;

        public WipItemsService(
            ISiteControlReader siteControlReader,
            IAvailableWipItemCommands availableWipItemCommands, 
            IExchangeDetailsResolver exchangeDetailsResolver,
            IDiscountsAndMargins discountsAndMargins,
            IDraftWipItem draftWipItem,
            Func<DateTime> now)
        {
            _siteControlReader = siteControlReader;
            _availableWipItemCommands = availableWipItemCommands;
            _exchangeDetailsResolver = exchangeDetailsResolver;
            _discountsAndMargins = discountsAndMargins;
            _draftWipItem = draftWipItem;
            _now = now;
        }

        public async Task<IEnumerable<AvailableWipItem>> GetAvailableWipItems(int userIdentityId, string culture, WipSelectionCriteria wipSelectionCriteria)
        {
            return await _availableWipItemCommands.GetAvailableWipItems(userIdentityId, culture, wipSelectionCriteria);
        }

        public async Task<WipItemExchangeRates> GetWipItemExchangeRates(int userIdentityId, string culture, string currencyCode, WipSelectionCriteria wipSelectionCriteria)
        {
            if (wipSelectionCriteria == null) throw new ArgumentNullException(nameof(wipSelectionCriteria));

            var exchangeRatesDetails = await _exchangeDetailsResolver.Resolve(userIdentityId, currencyCode, 
                                                                              transactionDate: wipSelectionCriteria.ItemDate, 
                                                                              caseId: wipSelectionCriteria.CaseIds.FirstOrDefault(), 
                                                                              nameId: wipSelectionCriteria.DebtorId);

            var wipItems = await _availableWipItemCommands.GetAvailableWipItems(userIdentityId, culture, wipSelectionCriteria);

            return new WipItemExchangeRates
            {
                DebtorExchangeRate = exchangeRatesDetails.SellRate ?? 0,
                WipItems = wipItems.Select(_ => new WipItemExchangeRate
                {
                    WipEntityId = _.EntityId,
                    WipTransactionId = _.TransactionId,
                    WipSequenceNo = _.WipSeqNo,
                    BillBuyRate = _.BillBuyRate,
                    BillSellRate = _.BillSellRate
                })
            };
        }

        public async Task<IEnumerable<AvailableWipItem>> RecalculateDiscounts(int userIdentityId, string culture, decimal billedAmount, int raisedByStaffId, IEnumerable<AvailableWipItem> wipItems)
        {
            if (wipItems == null) throw new ArgumentNullException(nameof(wipItems));

            var isDiscountInBilling = _siteControlReader.Read<bool>(SiteControls.DiscountNotInBilling) == false;

            var result = new List<AvailableWipItem>();

            var today = _now().Date;

            foreach (var wipItem in wipItems)
            {
                wipItem.LocalBilled = null;

                if (!isDiscountInBilling || wipItem.DebtorId == null)
                {
                    result.Add(wipItem);
                    continue;
                }

                var discountDetails = await _discountsAndMargins.GetDiscountDetails(userIdentityId, culture, (int) wipItem.DebtorId, wipItem.CaseId, raisedByStaffId, wipItem.EntityId);

                if (string.IsNullOrWhiteSpace(discountDetails.WipCode) || discountDetails.NarrativeId == null)
                {
                    result.Add(wipItem);
                    continue;
                }

                var billingDiscountAmount = await _discountsAndMargins.GetBillingDiscount(userIdentityId, culture, (int) wipItem.DebtorId, wipItem.CaseId, billedAmount);

                var discountValue = billingDiscountAmount * -1;

                wipItem.TransactionDate = today;
                wipItem.Description = discountDetails.WipDescription;
                wipItem.WipCode = discountDetails.WipCode;
                wipItem.WipCategory = discountDetails.WipCategory;
                wipItem.WipTypeId = discountDetails.WipTypeId;
                wipItem.WipCategorySortOrder = discountDetails.WipCategorySortOrder;
                wipItem.TaxCode = discountDetails.WipTaxCode;
                wipItem.NarrativeId = discountDetails.NarrativeId;
                wipItem.ShortNarrative = discountDetails.NarrativeText;
                wipItem.LocalBilled = discountValue;
                wipItem.Balance = discountValue;
                wipItem.IsDraft = true;

                wipItem.DraftWipData ??= new DraftWip
                {
                    CaseId = wipItem.CaseId,
                    CaseReference = wipItem.CaseRef,
                    EntryDate = wipItem.TransactionDate,
                    EntityId = wipItem.EntityId,
                    IsCreditWip = wipItem.IsCreditWip,
                    IsRenewal = wipItem.IsRenewal,
                    StaffId = wipItem.StaffId,
                    StaffName = wipItem.StaffName,
                    NameId = wipItem.DebtorId,
                    
                    IsDiscount = true,
                    IsWipItem = true,
                    IsBillingDiscount = true,
                    
                    ActivityId = discountDetails.WipCode,
                    Activity = discountDetails.WipDescription,
                    WipCategory = discountDetails.WipCategory,
                    WipTypeId = discountDetails.WipTypeId,
                    WipCategorySortOrder = discountDetails.WipCategorySortOrder,
                    NarrativeId = discountDetails.NarrativeId,
                    Narrative = discountDetails.NarrativeText,
                };

                wipItem.DraftWipData.LocalValue = discountValue;
                wipItem.DraftWipData.Balance = discountValue;

                result.Add(wipItem);
            }

            return result;
        }

        public async Task<IEnumerable<AvailableWipItem>> ConvertDraftWipToAvailableWipItems(int userIdentityId, string culture, 
                                                                                            CompleteDraftWipItem[] draftWipItems, 
                                                                                            ItemType itemType, int staffId, string billCurrency, DateTime billDate, int? caseId, int debtorId)
        {
            if (draftWipItems == null) throw new ArgumentNullException(nameof(draftWipItems));

            // TODO: REVIEW SIGNAGE.  This is simplified from AvailableWIPWorker.GetDraftWip

            IEnumerable<DraftWip> GetDraftWipItems()
            {
                foreach (var item in draftWipItems)
                {
                    if (item.IsWipItem == true)
                        yield return item;
                    
                    foreach (var feeItem in item.Split())
                        yield return feeItem;
                }
            }
            
            var availableWipItems = new List<AvailableWipItem>();
            var isCreditNote = itemType == ItemType.CreditNote || itemType == ItemType.InternalCreditNote;

            foreach (var item in GetDraftWipItems())
            {
                item.ReverseSignsForCreditFeeCharges(x => x.IsCreditWip == true);

                availableWipItems.AddRange(await _draftWipItem.ConvertToAvailableWipItems(userIdentityId, culture, item, billCurrency, billDate, staffId, debtorId, caseId));
            }

            return from availableWipItem in availableWipItems
                   let r = isCreditNote
                       ? availableWipItem.ReverseSignsForCreditNote()
                       : availableWipItem
                   select r;
        }

        public async Task<IEnumerable<AvailableWipItem>> ConvertStampFeeWipToAvailableWipItems(int userIdentityId, string culture, 
                                                                                               DraftWip draftWipItem, int staffId, DateTime billDate)
        {
            if (draftWipItem == null) throw new ArgumentNullException(nameof(draftWipItem));
            if (draftWipItem.NameId == null) throw new ArgumentException($"{nameof(draftWipItem.NameId)} is required");
            
            return await _draftWipItem.ConvertToAvailableWipItems(userIdentityId, culture, 
                                                                  draftWipItem, null, billDate, staffId, 
                                                                  (int) draftWipItem.NameId, draftWipItem.CaseId);
        }
    }
}
