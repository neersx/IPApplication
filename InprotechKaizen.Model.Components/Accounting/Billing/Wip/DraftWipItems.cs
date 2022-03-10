using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public interface IDraftWipItem
    {
        Task<IEnumerable<AvailableWipItem>> ConvertToAvailableWipItems(int userIdentityId, string culture, DraftWip draftWip, string billCurrency, DateTime billDate, int staffId, int debtorId, int? caseId);
    }

    public class DraftWipItem : IDraftWipItem
    {
        readonly IDiscountsAndMargins _discountsAndMargins;
        readonly IDraftWipAdditionalDetailsResolver _detailsResolver;

        public DraftWipItem(IDiscountsAndMargins discountsAndMargins,
                            IDraftWipAdditionalDetailsResolver detailsResolver)
        {
            _discountsAndMargins = discountsAndMargins;
            _detailsResolver = detailsResolver;
        }

        public async Task<IEnumerable<AvailableWipItem>> ConvertToAvailableWipItems(int userIdentityId, string culture, DraftWip draftWip, string billCurrency, DateTime billDate, int staffId, int debtorId, int? caseId)
        {
            if (draftWip == null) throw new ArgumentNullException(nameof(draftWip));

            var treatMarginSeparately = draftWip.IsSeparateMargin == true && draftWip.Margin.GetValueOrDefault() != 0;

            var localMargin = treatMarginSeparately ? draftWip.Margin : 0;
            var foreignMargin = treatMarginSeparately ? draftWip.ForeignMargin ?? 0 : 0;

            var margin = treatMarginSeparately
                ? await _discountsAndMargins.GetMarginDetails(userIdentityId, culture, debtorId, caseId, staffId, draftWip.EntityId, draftWip.IsRenewal)
                : new MarginDetails();

            var hasDiscounts = draftWip.LocalDiscount.GetValueOrDefault() != 0;

            var discount = hasDiscounts ? await _discountsAndMargins.GetDiscountDetails(userIdentityId, culture, debtorId, caseId, staffId, draftWip.EntityId) : null;
            var localDiscountForMargin = treatMarginSeparately ? draftWip.LocalDiscountForMargin ?? 0 : 0;
            var foreignDiscountForMargin = treatMarginSeparately ? draftWip.ForeignDiscountForMargin ?? 0 : 0;

            return new[]
            {
                await ConvertDraftWip(userIdentityId, culture,
                                      draftWip, billCurrency, billDate, debtorId, caseId, localMargin, foreignMargin, treatMarginSeparately),

                treatMarginSeparately
                    ? await ConvertDraftMarginWip(userIdentityId, culture, draftWip, billCurrency, billDate, debtorId, caseId, margin)
                    : null,

                hasDiscounts
                    ? await ConvertDraftDiscountWip(userIdentityId, culture,
                                                    draftWip, billCurrency, billDate, debtorId, caseId,
                                                    localDiscountForMargin, foreignDiscountForMargin, discount)
                    : null,

                hasDiscounts && treatMarginSeparately && localDiscountForMargin != 0
                    ? await ConvertDraftMarginOnDiscountWip(userIdentityId, culture,
                                                            draftWip, billCurrency, billDate, debtorId, caseId,
                                                            localDiscountForMargin, foreignDiscountForMargin, margin)
                    : null
            }.Where(_ => _ != null);
        }
        
        async Task<AvailableWipItem> ConvertDraftMarginOnDiscountWip(int userIdentityId, string culture, DraftWip draftWip, string billCurrency, DateTime billDate, int debtorId, int? caseId, decimal localDiscountForMargin, decimal foreignDiscountForMargin, MarginDetails margin)
        {
            return await WithCalculatedDetails(userIdentityId, culture, draftWip, debtorId, caseId, billCurrency, billDate,
                                               new AvailableWipItem
                                               {
                                                   IsDraft = true,
                                                   IsDiscount = true,
                                                   IsMargin = true,

                                                   Balance = localDiscountForMargin * -1,
                                                   LocalBilled = localDiscountForMargin * -1,

                                                   ForeignBalance = foreignDiscountForMargin * -1,
                                                   ForeignBilled = foreignDiscountForMargin * -1,
                                                   ForeignCurrency = draftWip.ForeignCurrencyCode
                                               }, margin);
        }

        async Task<AvailableWipItem> ConvertDraftDiscountWip(int userIdentityId, string culture, DraftWip draftWip, string billCurrency, DateTime billDate, int debtorId, int? caseId, decimal localDiscountForMargin, decimal foreignDiscountForMargin, DiscountDetails discount)
        {
            return await WithCalculatedDetails(userIdentityId, culture, draftWip, debtorId, caseId, billCurrency, billDate,
                                               new AvailableWipItem
                                               {
                                                   IsDraft = true,
                                                   IsDiscount = true,

                                                   Balance = (draftWip.LocalDiscount - localDiscountForMargin) * -1,
                                                   LocalBilled = (draftWip.LocalDiscount - localDiscountForMargin) * -1,

                                                   ForeignBalance = (draftWip.ForeignDiscount - foreignDiscountForMargin) * -1,
                                                   ForeignBilled = (draftWip.ForeignDiscount - foreignDiscountForMargin) * -1,
                                                   ForeignCurrency = draftWip.ForeignCurrencyCode
                                               }, discount);
        }

        async Task<AvailableWipItem> ConvertDraftMarginWip(int userIdentityId, string culture, DraftWip draftWip, string billCurrency, DateTime billDate, int debtorId, int? caseId, MarginDetails margin)
        {
            return await WithCalculatedDetails(userIdentityId, culture, draftWip, debtorId, caseId, billCurrency, billDate,
                                               new AvailableWipItem
                                               {
                                                   IsDraft = true,
                                                   IsMargin = true,

                                                   Balance = draftWip.Margin,
                                                   LocalBilled = draftWip.Margin,

                                                   ForeignBalance = draftWip.ForeignMargin,
                                                   ForeignBilled = draftWip.ForeignMargin,
                                                   ForeignCurrency = draftWip.ForeignCurrencyCode
                                               }, margin);
        }

        async Task<AvailableWipItem> ConvertDraftWip(int userIdentityId, string culture, DraftWip draftWip, string billCurrency, DateTime billDate, int debtorId, int? caseId, decimal? localMargin, decimal foreignMargin, bool treatMarginSeparately)
        {
            return await WithCalculatedDetails(userIdentityId, culture, draftWip, debtorId, caseId, billCurrency, billDate,
                                               new AvailableWipItem
                                               {
                                                   IsDraft = true,

                                                   Balance = draftWip.LocalValue - localMargin,
                                                   LocalBilled = draftWip.LocalValue - localMargin,

                                                   ForeignBalance = draftWip.ForeignValue - foreignMargin,
                                                   ForeignBilled = draftWip.ForeignValue - foreignMargin,
                                                   ForeignCurrency = draftWip.ForeignCurrencyCode,

                                                   ChargeOutRate = draftWip.ChargeOutRate,
                                                   UnitsPerHour = draftWip.UnitsPerHour,

                                                   TotalUnits = draftWip.TotalUnits,
                                                   TotalTime = draftWip.TotalTime != null && draftWip.TotalTime != 0
                                                       ? new DateTime(1899, 01, 01, draftWip.TotalTime.Value / 60, draftWip.TotalTime.Value % 60, 0)
                                                       : null,

                                                   CostCalculation1 = draftWip.CostCalculation1,
                                                   CostCalculation2 = draftWip.CostCalculation2,
                                                   MarginNo = draftWip.MarginNo,
                                                   OneFeePerDebtor = draftWip.IsOneFeePerDebtor,
                                                   DraftWipRefId = treatMarginSeparately ? null : draftWip.DraftWipRefId,
                                                   DraftWipData = draftWip
                                               });
        }

        async Task<AvailableWipItem> WithCalculatedDetails(
            int userIdentityId, string culture, DraftWip draftWip, int debtorId, int? caseId, string billCurrency, DateTime billDate, AvailableWipItem availableWipItem, WipDetails discountOrMargin = null)
        {
            if (draftWip.EntityId == null) throw new ArgumentException($"draftWip must have '{nameof(draftWip.EntityId)}' specified.");

            var details = await _detailsResolver.Resolve(userIdentityId, culture,
                                                         debtorId, caseId,
                                                         billCurrency,
                                                         billDate,
                                                         draftWip.StaffId,
                                                         draftWip.EntityId,
                                                         draftWip.EntryDate,
                                                         draftWip.WipTypeId,
                                                         draftWip.WipCategory,
                                                         draftWip.WipCode ?? draftWip.ActivityId);

            availableWipItem.StaffSignOffName = details.StaffSignOffName;
            availableWipItem.BillBuyRate = details.BillBuyRate;
            availableWipItem.BillSellRate = details.BillSellRate;
            availableWipItem.WipTypeDescription = details.WipTypeDescription;
            availableWipItem.WipCategoryDescription = details.WipCategoryDescription;

            availableWipItem.WipTypeSortOrder = discountOrMargin?.WipTypeSortOrder ?? details.WipTypeSortOrder;
            availableWipItem.WipCategorySortOrder = discountOrMargin?.WipCategorySortOrder ?? details.WipCategorySortOrder;
            availableWipItem.WipCodeSortOrder = discountOrMargin?.WipCodeSortOrder ?? details.WipCodeSortOrder;
            availableWipItem.TaxCode = discountOrMargin?.WipTaxCode ?? details.TaxCode;

            availableWipItem.TaxRate = details.TaxRate;

            availableWipItem.StaffId = draftWip.StaffId;
            availableWipItem.StaffName = draftWip.StaffName;
            availableWipItem.WipCode = discountOrMargin?.WipCode ?? draftWip.ActivityId;
            availableWipItem.WipCategory = discountOrMargin?.WipCategory ?? draftWip.WipCategory;
            availableWipItem.Description = discountOrMargin?.WipDescription ?? draftWip.Activity;
            availableWipItem.NarrativeId = discountOrMargin?.NarrativeId ?? draftWip.NarrativeId;
            availableWipItem.ShortNarrative = discountOrMargin?.NarrativeText ?? draftWip.Narrative;
            availableWipItem.WipTypeId = discountOrMargin?.WipTypeId ?? draftWip.WipTypeId;

            if (draftWip.IsBillingDiscountOrStampFee)
            {
                draftWip.ProfitCentreCode = details.ProfitCentreCode;
                draftWip.ProfitCentre = details.ProfitCentre;
            }

            availableWipItem.StaffProfitCentre = draftWip.ProfitCentreCode;
            availableWipItem.ProfitCentreDescription = draftWip.ProfitCentre;
            availableWipItem.EntityId = (int)draftWip.EntityId;
            availableWipItem.CaseId = draftWip.CaseId;
            availableWipItem.CaseRef = draftWip.CaseReference;
            availableWipItem.TransactionDate = draftWip.EntryDate;
            availableWipItem.SplitGroupKey = draftWip.SplitGroupKey;
            availableWipItem.GeneratedFromTaxCode = draftWip.IsGeneratedFromTaxCode ?? string.Empty;
            availableWipItem.RateNoSortOrder = draftWip.RateNoSort;

            availableWipItem.IsCreditWip = draftWip.IsCreditWip;
            availableWipItem.IsAdvanceBill = draftWip.IsAdvanceBill;
            availableWipItem.IsRenewal = draftWip.IsRenewal ?? false;
            availableWipItem.IsFeeType = draftWip.IsFeeType;

            return availableWipItem;
        }
    }
}
