using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Policy;
using InprotechKaizen.Model.Components.Accounting.Billing;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public interface IDebtorWipSplitter
    {
        Task<IEnumerable<UnpostedWip>> Split(string requestedCulture, UnpostedWip original);
    }

    public class DebtorWipSplitter : IDebtorWipSplitter
    {
        readonly IBestTranslatedNarrativeResolver _bestNarrativeResolver;
        readonly ILogger<DebtorWipSplitter> _logger;
        readonly ISiteCurrencyFormat _siteCurrencyFormat;
        readonly IWipCosting _wipCosting;
        readonly IWipDebtorSelector _wipDebtorSelector;

        public DebtorWipSplitter(ILogger<DebtorWipSplitter> logger,
                                 IWipCosting wipCosting,
                                 IWipDebtorSelector wipDebtorSelector,
                                 IBestTranslatedNarrativeResolver bestNarrativeResolver,
                                 ISiteCurrencyFormat siteCurrencyFormat)
        {
            _logger = logger;
            _wipCosting = wipCosting;
            _wipDebtorSelector = wipDebtorSelector;
            _bestNarrativeResolver = bestNarrativeResolver;
            _siteCurrencyFormat = siteCurrencyFormat;
        }

        public async Task<IEnumerable<UnpostedWip>> Split(string requestedCulture, UnpostedWip original)
        {
            if (original == null) throw new ArgumentNullException(nameof(original));
            if (original.CaseKey == null) throw new ArgumentException("Case must be provided", nameof(original.CaseKey));

            var debtors = _wipDebtorSelector.GetDebtorsForCaseWip(original.CaseKey.Value, original.WipCode).ToArray();

            var splits = new List<UnpostedWip>();

            foreach (var debtor in debtors)
            {
                debtor.DefaultNarrative = await _bestNarrativeResolver.Resolve(requestedCulture,
                                                                               original.WipCode,
                                                                               original.StaffKey,
                                                                               original.CaseKey,
                                                                               debtor.NameId);

                splits.Add(debtor == debtors.Last()
                               ? AllocateRemainder(original, debtor, splits.ToArray())
                               : SplitForDebtor(original, debtor));
            }

            var costedSplits = new List<UnpostedWip>();
            foreach (var split in splits) costedSplits.Add(await WipCosting(split));

            var aggregatedWip = AggregateSplits(original, costedSplits.ToArray());

            var result = new List<UnpostedWip>().AddAll(new[] {aggregatedWip}, costedSplits);

            _logger.Trace("Debtor WIP Split", new
            {
                original,
                preCostedSplits = splits,
                costedSplits,
                aggregatedWip
            });

            return result;
        }

        async Task<UnpostedWip> WipCosting(UnpostedWip split)
        {
            var costedWip = await _wipCosting.For(split);

            split.LocalValue = costedWip.LocalValue;
            split.DiscountValue = costedWip.LocalDiscount;
            split.DiscountForMargin = costedWip.LocalDiscountForMargin;

            if (!string.IsNullOrWhiteSpace(costedWip.CurrencyCode))
            {
                split.ForeignCost = costedWip.ForeignValue - costedWip.MarginValue.GetValueOrDefault();
                split.ForeignCurrency = costedWip.CurrencyCode;
                split.ForeignValue = costedWip.ForeignValue;
                split.ForeignDiscount = costedWip.ForeignDiscount;
                split.ForeignDiscountForMargin = costedWip.ForeignDiscountForMargin;
                split.ExchangeRate = costedWip.ExchangeRate;
            }

            if (costedWip.LocalValue != null)
            {
                split.LocalCost = costedWip.LocalValueBeforeMargin;
                split.CostCalculation1 = costedWip.CostCalculation1;
                split.CostCalculation2 = costedWip.CostCalculation2;
            }

            split.TotalUnits = costedWip.TimeUnits;
            split.TotalTime = costedWip.Hours;
            split.ChargeOutRate = costedWip.ChargeOutRate;
            split.MarginNo = costedWip.MarginNo;

            if (costedWip.MarginValue != null)
            {
                if (costedWip.ForeignValue != null)
                {
                    split.ForeignMargin = costedWip.MarginValue;
                    split.MarginValue = costedWip.LocalValue - costedWip.LocalValueBeforeMargin;
                }
                else
                {
                    split.MarginValue = costedWip.MarginValue;
                }
            }

            return split;
        }

        UnpostedWip SplitForDebtor(UnpostedWip parentWip, Debtor debtor)
        {
            var newWip = (UnpostedWip) parentWip.Clone();
            var decimalPlaces = GetLocalCurrencyDecimalPlaces();
            SetDebtorDetails(debtor, newWip);

            if (!newWip.IsSplitTimeByDebtor())
            {
                switch (parentWip.State())
                {
                    case WipItemState.LocalValueOnly:
                        newWip.LocalCost = SplitByPercentage(parentWip.LocalCost.GetValueOrDefault(), debtor.BillingPercentage.GetValueOrDefault(), decimalPlaces);
                        break;
                    case WipItemState.ForeignValueOnly:
                        newWip.ForeignCost = SplitByPercentage(parentWip.ForeignCost.GetValueOrDefault(),
                                                               debtor.BillingPercentage.GetValueOrDefault(), decimalPlaces);
                        break;
                    case WipItemState.LocalAndForeign:
                        newWip.LocalCost = SplitByPercentage(parentWip.LocalCost.GetValueOrDefault(), debtor.BillingPercentage.GetValueOrDefault(), decimalPlaces);
                        newWip.ForeignCost = SplitByPercentage(parentWip.ForeignCost.GetValueOrDefault(),
                                                               debtor.BillingPercentage.GetValueOrDefault(), decimalPlaces);
                        break;
                }
            }

            return newWip;
        }

        int GetLocalCurrencyDecimalPlaces()
        {
            return _siteCurrencyFormat.Resolve().LocalDecimalPlaces;
        }

        static UnpostedWip AllocateRemainder(UnpostedWip parentWip, Debtor debtor, UnpostedWip[] allocatedWip)
        {
            var newWip = (UnpostedWip) parentWip.Clone();
            SetDebtorDetails(debtor, newWip);
            if (!newWip.IsSplitTimeByDebtor())
            {
                switch (parentWip.State())
                {
                    case WipItemState.LocalValueOnly:
                        newWip.LocalCost = parentWip.LocalCost - allocatedWip.Sum(w => w.LocalCost.GetValueOrDefault());
                        break;
                    case WipItemState.ForeignValueOnly:
                        newWip.ForeignCost = parentWip.ForeignCost - allocatedWip.Sum(w => w.ForeignCost.GetValueOrDefault());
                        break;
                    case WipItemState.LocalAndForeign:
                        newWip.LocalCost = parentWip.LocalCost - allocatedWip.Sum(w => w.LocalCost.GetValueOrDefault());
                        newWip.ForeignCost = parentWip.ForeignCost - allocatedWip.Sum(w => w.ForeignCost.GetValueOrDefault());
                        break;
                }
            }

            return newWip;
        }

        static void SetDebtorDetails(Debtor debtor, UnpostedWip newWip)
        {
            newWip.NameKey = debtor.NameId;
            newWip.DebtorNameTypeKey = debtor.NameType;
            newWip.DebtorSplitPercentage = debtor.BillingPercentage.GetValueOrDefault();
            if (!newWip.NarrativeKey.HasValue) return;
            newWip.NarrativeKey = debtor.DefaultNarrative?.Key;
            newWip.NarrativeTitle = debtor.DefaultNarrative?.Value;
            newWip.Narrative = debtor.DefaultNarrative?.Text;
        }

        static decimal SplitByPercentage(decimal amount, decimal percentage, int decimalPlaces)
        {
            return Math.Round(amount * (percentage / 100), decimalPlaces, MidpointRounding.AwayFromZero);
        }

        static UnpostedWip AggregateSplits(UnpostedWip originalWip, UnpostedWip[] splitWip)
        {
            var aggregatedWip = (UnpostedWip) originalWip.Clone();
            aggregatedWip.IsSplitDebtorWip = true;
            aggregatedWip.DebtorNameTypeKey = splitWip.First().DebtorNameTypeKey;
            aggregatedWip.LocalCost = splitWip.Sum(w => w.LocalCost.GetValueOrDefault());
            aggregatedWip.LocalValue = splitWip.Sum(w => w.LocalValue.GetValueOrDefault());
            aggregatedWip.DiscountValue = splitWip.Sum(w => w.DiscountValue.GetValueOrDefault());
            aggregatedWip.MarginValue = splitWip.Sum(w => w.MarginValue.GetValueOrDefault());
            aggregatedWip.DiscountForMargin = splitWip.Sum(w => w.DiscountForMargin.GetValueOrDefault());

            var firstChargeRate = splitWip.First().ChargeOutRate;
            aggregatedWip.ChargeOutRate = splitWip.Any(w => w.ChargeOutRate != firstChargeRate) ? null : firstChargeRate;

            if (splitWip.All(s => !string.IsNullOrWhiteSpace(s.ForeignCurrency)) &&
                splitWip.GroupBy(s => s.ForeignCurrency).Count() == 1)
            {
                aggregatedWip.ForeignCurrency = splitWip.First().ForeignCurrency;
                aggregatedWip.ForeignCost = splitWip.Sum(w => w.ForeignCost.GetValueOrDefault());
                aggregatedWip.ForeignValue = splitWip.Sum(w => w.ForeignValue.GetValueOrDefault());
                aggregatedWip.ForeignDiscount = splitWip.Sum(w => w.ForeignDiscount.GetValueOrDefault());
                aggregatedWip.ForeignMargin = splitWip.Sum(w => w.ForeignMargin.GetValueOrDefault());
                aggregatedWip.ForeignDiscountForMargin = splitWip.Sum(w => w.ForeignDiscountForMargin.GetValueOrDefault());
                aggregatedWip.ExchangeRate = aggregatedWip.LocalCost.GetValueOrDefault() > 0
                    ? Math.Round(
                                 aggregatedWip.ForeignCost.GetValueOrDefault() /
                                 aggregatedWip.LocalCost.GetValueOrDefault(), 4, MidpointRounding.AwayFromZero)
                    : 0;
            }

            return aggregatedWip;
        }
    }
}