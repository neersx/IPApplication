using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Wip;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class TimeSplitter : ITimeSplitter
    {
        readonly IWipDebtorSelector _wipDebtorSelector;
        readonly IWipCosting _wipCosting;
        readonly IBestTranslatedNarrativeResolver _bestNarrativeResolver;
        
        public TimeSplitter(IWipDebtorSelector wipDebtorSelector, IWipCosting wipCosting, IBestTranslatedNarrativeResolver bestNarrativeResolver)
        {
            _wipDebtorSelector = wipDebtorSelector;
            _wipCosting = wipCosting;
            _bestNarrativeResolver = bestNarrativeResolver;
        }

        public async Task<RecordableTime> SplitTime(string requestedCulture, RecordableTime time, int staffKey)
        {
            if (time.CaseKey == null) return time;

            var debtors = _wipDebtorSelector.GetDebtorsForCaseWip(time.CaseKey.Value, time.ActivityKey).ToArray();

            if (debtors.Length <= 1)
            {
                time.DebtorSplits.Clear();
                return time;
            }

            time.IsSplitDebtorWip = true;
            var debtorSplits = new List<DebtorSplit>();
            var hasExistingSplitNarratives = time.DebtorSplits?.Any(d => d.NarrativeNo != null || d.Narrative != null) == true;

            foreach (var d in debtors)
            {
                time.NameKey = d.NameId;
                time.DebtorNameTypeKey = d.NameType;
                var wipCost = await _wipCosting.For(time);
                var debtorSplit = new DebtorSplit
                {
                    DebtorNameNo = d.NameId,
                    ForeignCurrency = wipCost.CurrencyCode,
                    LocalValue = wipCost.LocalValue,
                    ChargeOutRate = wipCost.ChargeOutRate,
                    LocalDiscount = wipCost.LocalDiscount,
                    ForeignValue = wipCost.ForeignValue,
                    ExchRate = wipCost.ExchangeRate,
                    ForeignDiscount = wipCost.ForeignDiscount,
                    MarginNo = wipCost.MarginNo,
                    SplitPercentage = d.BillingPercentage,
                    CostCalculation1 = wipCost.CostCalculation1,
                    CostCalculation2 = wipCost.CostCalculation2,
                    UnitsPerHour = wipCost.UnitsPerHour
                };

                if (hasExistingSplitNarratives)
                {
                    var oldDebtorSplit = time.DebtorSplits.FirstOrDefault(dsd => dsd.DebtorNameNo == debtorSplit.DebtorNameNo);
                    if (oldDebtorSplit != null)
                    {
                        debtorSplit.NarrativeNo = oldDebtorSplit.NarrativeNo;
                        debtorSplit.Narrative = oldDebtorSplit.Narrative;
                    }
                }

                debtorSplits.Add(debtorSplit);

                if (d == debtors.Last())
                {
                    time.TotalUnits = wipCost.TimeUnits;
                }
            }

            time.DebtorSplits = debtorSplits;
            if (!hasExistingSplitNarratives)
            {
                await FillDefaultNarrativesForEachDebtorSplit(requestedCulture, time, staffKey);
            }
            
            return time;
        }

        async Task FillDefaultNarrativesForEachDebtorSplit(string requestedCulture, RecordableTime time, int staffKey)
        {
            if (time.CaseKey == null || time.ActivityKey == null && time.Activity == null) return;

            foreach (var ds in time.DebtorSplits)
            {
                if (time.NarrativeNo != null)
                {
                    var defaultNarrative = await _bestNarrativeResolver.Resolve(requestedCulture, time.ActivityKey ?? time.Activity, staffKey, time.CaseKey);
                    if (defaultNarrative == null || defaultNarrative.Key != time.NarrativeNo)
                    {
                        ds.NarrativeNo = time.NarrativeNo;
                        ds.Narrative = time.NarrativeText;
                    }
                    else
                    {
                        await DeriveNarrativePerDebtor(ds);
                    }
                }
                else
                {
                    if (!string.IsNullOrEmpty(time.NarrativeText))
                    {
                        ds.Narrative = time.NarrativeText;
                        ds.NarrativeNo = null;
                    }
                    else
                    {
                        await DeriveNarrativePerDebtor(ds);
                    }
                }
            }

            async Task DeriveNarrativePerDebtor(DebtorSplit ds)
            {
                var bestNarrative = await _bestNarrativeResolver.Resolve(requestedCulture, time.ActivityKey ?? time.Activity, staffKey, time.CaseKey, ds.DebtorNameNo);
                if (bestNarrative == null) return;

                ds.NarrativeNo = bestNarrative.Key;
                ds.Narrative = bestNarrative.Text;
            }
        }

        public TimeEntry AggregateSplitIntoTime(RecordableTime time)
        {
            var firstWip = time.DebtorSplits.First();
            var wipCost = new TimeEntry
            {
                CaseKey = time.CaseKey,
                ActivityKey = time.ActivityKey,
                TotalUnits = time.TotalUnits,
                LocalValue = time.DebtorSplits.Sum(dsw => dsw.LocalValue),
                LocalDiscount = time.DebtorSplits.Sum(dsw => dsw.LocalDiscount),
                ForeignCurrency = time.DebtorSplits.GroupBy(dsw => dsw.ForeignCurrency)
                                      .Count() >
                                  1
                    ? null
                    : firstWip.ForeignCurrency
            };
            if (!string.IsNullOrEmpty(wipCost.ForeignCurrency))
            {
                wipCost.ForeignValue = time.DebtorSplits.Sum(dsw => dsw.ForeignValue);
                wipCost.ForeignDiscount = time.DebtorSplits.Sum(dsw => dsw.ForeignDiscount);
                wipCost.ExchangeRate = wipCost.LocalValue.GetValueOrDefault(0) == 0 ? null : wipCost.ForeignValue / wipCost.LocalValue;
            }
            else
            {
                wipCost.ForeignValue = null;
                wipCost.ForeignDiscount = null;
                wipCost.ExchangeRate = null;
            }

            wipCost.ChargeOutRate = time.DebtorSplits.GroupBy(dsw => dsw.ChargeOutRate).Count() > 1 ?
                null :
                firstWip.ChargeOutRate;

            wipCost.CostCalculation1 = time.DebtorSplits.Sum(dsw => dsw.CostCalculation1);
            wipCost.CostCalculation2 = time.DebtorSplits.Sum(dsw => dsw.CostCalculation2);  
            wipCost.MarginNo = time.DebtorSplits.GroupBy(dsw => dsw.MarginNo).Count() > 1 ?
                null :
                firstWip.MarginNo;
            
            wipCost.DebtorSplits = time.DebtorSplits;
            wipCost.UnitsPerHour = firstWip.UnitsPerHour;

            return wipCost;
        }
    }

    public interface ITimeSplitter
    {
        Task<RecordableTime> SplitTime(string requestedCulture, RecordableTime time, int staffKey);
        TimeEntry AggregateSplitIntoTime(RecordableTime time);
    }
}