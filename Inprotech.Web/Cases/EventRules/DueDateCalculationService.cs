using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.Cases.EventRules.Models;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;

namespace Inprotech.Web.Cases.EventRules
{
    public interface IDueDateCalculationService
    {
        DueDateCalculationInfo GetDueDateCalculations(EventViewRuleDetails details);
    }

    public class DueDateCalculationService : IDueDateCalculationService
    {
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _translator;
        readonly ISiteControlReader _siteControlReader;
        readonly IEventRulesHelper _eventRulesHelper;
        const string DueDateCalcTranslate = "caseview.eventRules.dueDateCalculations.";

        public DueDateCalculationService(
                                 IPreferredCultureResolver preferredCultureResolver,
                                 IStaticTranslator translator,
                                 ISiteControlReader siteControlReader,
                                 IEventRulesHelper eventRulesHelper
        )
        {
            _preferredCultureResolver = preferredCultureResolver;
            _translator = translator;
            _siteControlReader = siteControlReader;
            _eventRulesHelper = eventRulesHelper;
        }

        public DueDateCalculationInfo GetDueDateCalculations(EventViewRuleDetails details)
        {
            var ddInfo = new DueDateCalculationInfo();
            
            var cultureResolver = _preferredCultureResolver.ResolveAll().ToArray();
            var scDateStyle = _siteControlReader.Read<int>(SiteControls.DateStyle);
            var dateStyle = DateStyleHelper.GetDateStyle(scDateStyle, _preferredCultureResolver.Resolve());
            var hasEventControlDetails = details.EventControlDetails != null;

            ddInfo.DueDateCalculation = GetDueDateCalc(details, cultureResolver, dateStyle);
            var hasData = ddInfo.DueDateCalculation.Any();

            if (hasEventControlDetails)
            {
                var ec = details.EventControlDetails;
                ddInfo.Heading = !hasData ? string.Empty : DueDateCalcTranslate + "heading_" + DueDateTypeHelper.StringToDueDateType(ec.WhichDueDate);

                var hasStandingInstruction = GetStandingInstruction(ec, ddInfo, cultureResolver);
                var hasDateComparisons = GetDateComparisonDetails(details, cultureResolver, ddInfo, dateStyle);
                var hasSatisfyingEvents = GetRelatedEvents(details, ddInfo, cultureResolver);
                hasData = hasData || hasStandingInstruction || hasDateComparisons || hasSatisfyingEvents;

                var extendPeriodType = PeriodTypeHelper.StringToPeriodType(ec.ExtendPeriodType);
                if (extendPeriodType != PeriodType.NotSet && ec.ExtendPeriod.GetValueOrDefault() != 0)
                {
                    ddInfo.ExtensionInfo = _eventRulesHelper.PeriodTypeToLocalizedString(ec.ExtendPeriod, extendPeriodType, cultureResolver);
                    hasData = true;
                }

                if (ec.SaveDueDate.GetValueOrDefault())
                {
                    ddInfo.HasSaveDueDateInfo = true;
                    hasData = true;
                }

                if (ec.RecalcEventDate.GetValueOrDefault())
                {
                    ddInfo.HasRecalculateInfo = true;
                    hasData = true;
                }
            }

            if (!hasData)
            {
                ddInfo = null;
            }

            return ddInfo;
        }

        bool GetStandingInstruction(EventControlDetails ec, DueDateCalculationInfo ddInfo, string[] cultureResolver)
        {
            if (string.IsNullOrEmpty(ec.InstructionType) || string.IsNullOrEmpty(ec.InstructionFlag)) return false;
            ddInfo.StandingInstructionInfo = string.Format(_translator.Translate(DueDateCalcTranslate + "calculateOnlyFor", cultureResolver),
                                                           "\"" + ec.InstructionType + "\"",
                                                           "\"" + ec.InstructionFlag + "\"");

            return true;
        }

        bool GetRelatedEvents(EventViewRuleDetails details, DueDateCalculationInfo ddInfo, string[] cultureResolver)
        {
            if (details.RelatedEventDetails == null || !details.RelatedEventDetails.Any()) return false;
            var satisfiedEvents = (from ddRelatedEvents in details.RelatedEventDetails
                                        where ddRelatedEvents.SatisfyEvent.GetValueOrDefault()
                                        select new DueDateSatisfiedByItem
                                        {
                                            EventKey = ddRelatedEvents.RelatedEvent,
                                            FormattedDescription = $"{ddRelatedEvents.RelatedEventDesc} [{_eventRulesHelper.RelativeCycleToLocalizedString(ddRelatedEvents.RelativeCycle, cultureResolver)}]"
                                        }).ToArray();
            ddInfo.DueDateSatisfiedBy = satisfiedEvents.Any() ? satisfiedEvents : null;
            return satisfiedEvents.Any();
        }

        bool GetDateComparisonDetails(EventViewRuleDetails details, string[] cultureResolver, DueDateCalculationInfo ddInfo, string dateStyle)
        {
            if (details.DateComparisonDetails == null || !details.DateComparisonDetails.Any()) return false;
            var booleanComparison = BooleanComparisonHelper.StringToBooleanComparison(details.EventControlDetails.CompareBoolean);
            var info = booleanComparison != BooleanComparison.NotSet ? _translator.Translate(DueDateCalcTranslate + "calculateOnlyIf_" + booleanComparison, cultureResolver) : string.Empty;
            var ddCompareInfo = _translator.Translate(DueDateCalcTranslate + "calculateOnlyIf", cultureResolver);
            ddInfo.DueDateComparisonInfo = string.Format(ddCompareInfo, info);

            ddInfo.DueDateComparison = from ddCompare in details.DateComparisonDetails
                                       select new DueDateComparisonItem
                                       {
                                           LeftHandSideEventKey = ddCompare.FromEvent,
                                           LeftHandSide = $"{ddCompare.FromEventDesc} [{_eventRulesHelper.RelativeCycleToLocalizedString(ddCompare.RelativeCycle, cultureResolver)}] {_eventRulesHelper.DateTypeToLocalizedString(ddCompare.EventDateFlag, cultureResolver)}",
                                           Comparison = _eventRulesHelper.ComparisonOperatorToSymbol(ddCompare.Comparison, cultureResolver),
                                           RightHandSideEventKey = ddCompare.CompareEvent,
                                           RightHandSide = RightHandSideComparisonValue(ddCompare, dateStyle, cultureResolver)
                                       };
            return true;

        }

        IEnumerable<DueDateCalculationItem> GetDueDateCalc(EventViewRuleDetails details, string[] cultureResolver, string dateStyle)
        {
            var dueDateCalc = new List<DueDateCalculationItem>();
            foreach (var dd in details.DueDateCalculationDetails)
            {
                var dueDateCalcItem = new DueDateCalculationItem {Or = dd != details.DueDateCalculationDetails.First()};

                var dueDateCalcPeriod = (dd.DeadlinePeriod.HasValue && dd.DeadlinePeriod.Value == 0) ? string.Empty : _eventRulesHelper.PeriodTypeToLocalizedString(dd.DeadlinePeriod, dd.PeriodType, cultureResolver);

                var calcPeriod = string.IsNullOrWhiteSpace(dueDateCalcPeriod) ? string.Empty : DateOperatorHelper.DateOperatorToSymbol(DateOperatorHelper.StringToDateOperator(dd.Operator));
                var formattedDueDateCalculation = $"{_eventRulesHelper.DateTypeToLocalizedString(dd.EventDateFlag, cultureResolver)} {calcPeriod} {dueDateCalcPeriod}".MakeSentenceLike();

                var workDay = WorkDayTypeHelper.ToWorkDayType(dd.WorkDay);
                var formattedWorkDayAdjustment = workDay == WorkDayType.NotSet ? null : _translator.Translate(DueDateCalcTranslate + "moveTo" + workDay, cultureResolver);

                var formattedAdjustedTo = string.IsNullOrEmpty(dd.Adjustment) ? null : $"{_translator.Translate(DueDateCalcTranslate + "adjustedTo", cultureResolver)} \"{dd.Adjustment}\"";

                var relativeCycleString = _eventRulesHelper.RelativeCycleToLocalizedString(dd.RelativeCycle, cultureResolver);
                dueDateCalcItem.FormattedDescription = $"{dd.FromEventDesc} [{relativeCycleString}] {formattedDueDateCalculation} {formattedWorkDayAdjustment} {formattedAdjustedTo}".MakeSentenceLike();

                dueDateCalcItem.CalculatedFromLabel = dd.FromDate.HasValue ? DueDateCalcTranslate + "calculatedFromDate" : DueDateCalcTranslate + "calculatedFromEvent";

                dueDateCalcItem.FromDateFormatted = dd.FromDate.HasValue ? dd.FromDate?.ToString(dateStyle) : string.Empty;
                dueDateCalcItem.EventKey = dd.FromEvent;
                dueDateCalcItem.CaseKey = dd.CaseId;
                dueDateCalcItem.CaseReference = details.EventControlDetails?.Irn;
                dueDateCalcItem.Cycle = dd.FromCycle;
                dueDateCalcItem.MustExist = dd.MustExist;

                dueDateCalc.Add(dueDateCalcItem);
            }

            return dueDateCalc;
        }

        string RightHandSideComparisonValue(DateComparisonDetails dcDetails, string dateStyle, string[] cultureResolver)
        {
            if (dcDetails.CompareSystemDate.GetValueOrDefault() && dcDetails.ComparisonDate.HasValue)
            {
                return _translator.Translate(DueDateCalcTranslate + "systemDate", cultureResolver);
            }
            if (dcDetails.CompareDate.HasValue)
            {
                return dcDetails.CompareDate?.ToString(dateStyle);
            }

            var comparison = _eventRulesHelper.StringToComparisonOperator(dcDetails.Comparison);

            if (comparison == ComparisonOperator.Exists || comparison == ComparisonOperator.NotExists)
                return string.Empty;

            return $"{dcDetails.CompareEventDesc} [{_eventRulesHelper.RelativeCycleToLocalizedString(dcDetails.CompareCycle, cultureResolver)}] {_eventRulesHelper.DateTypeToLocalizedString(dcDetails.CompareEventFlag, cultureResolver)}";
        }
    }
}
