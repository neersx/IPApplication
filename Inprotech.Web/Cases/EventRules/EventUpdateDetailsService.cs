using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules.Models;
using System.Linq;
using System.Text;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;

namespace Inprotech.Web.Cases.EventRules
{
    public interface IEventUpdateDetailsService
    {
        EventUpdateInfo GetEventUpdateDetails(EventViewRuleDetails details);
    }
    public class EventUpdateDetailsService : IEventUpdateDetailsService
    {
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _translator;
        readonly IEventRulesHelper _eventRulesHelper;
        const string EventUpdateTranslate = "caseview.eventRules.eventUpdate.";

        public EventUpdateDetailsService(
            IPreferredCultureResolver preferredCultureResolver,
            IStaticTranslator translator,
            IEventRulesHelper eventRulesHelper
        )
        {
            _preferredCultureResolver = preferredCultureResolver;
            _translator = translator;
            _eventRulesHelper = eventRulesHelper;
        }

        public EventUpdateInfo GetEventUpdateDetails(EventViewRuleDetails details)
        {
            var info = new EventUpdateInfo();
            var ec = details.EventControlDetails;
            var cultureResolver = _preferredCultureResolver.ResolveAll().ToArray();
            var hasData = false;
            if (ec != null)
            {
                info.UpdateImmediatelyInfo = ec.UpdateEventImmediately.GetValueOrDefault();
                info.UpdateWhenDueInfo = ec.UpdateWhenDue.GetValueOrDefault();
                info.Status = ec.Status;
                info.CreateAction = ec.CreateAction;
                info.CloseAction = ec.CloseAction;
                var hasChargesData = GetCharges(ec, cultureResolver, info);
                var hasReportToCpaData = HasReportToCpaData(ec, cultureResolver, info);

                hasData = info.UpdateImmediatelyInfo || info.UpdateWhenDueInfo || 
                          !string.IsNullOrEmpty(ec.Status) || !string.IsNullOrEmpty(ec.CreateAction) 
                          || !string.IsNullOrEmpty(ec.CloseAction) || hasChargesData || hasReportToCpaData;
            }

            var hasRelatedEventDetails = GetRelatedEventDetails(details, info, cultureResolver);
            hasData = hasData || hasRelatedEventDetails;

            if (!hasData)
            {
                info = null;
            }

            return info;
        }

        bool HasReportToCpaData(EventControlDetails ec, string[] cultureResolver, EventUpdateInfo info)
        {
            if (!ec.SetThirdPartyOn.HasValue && !ec.SetThirdPartyOff.HasValue) return false;

            var thirdPartySetting = string.Empty;
            if (ec.SetThirdPartyOn.HasValue && ec.SetThirdPartyOn == true)
            {
                thirdPartySetting = "BooleanLiteral_True";
            }
            else if (ec.SetThirdPartyOff.HasValue && ec.SetThirdPartyOff == true)
            {
                thirdPartySetting = "BooleanLiteral_False";
            }

            if (string.IsNullOrEmpty(thirdPartySetting)) return false;

            thirdPartySetting = _translator.Translate(EventUpdateTranslate + thirdPartySetting, cultureResolver);
            info.ReportToCpaInfo = $"{_translator.Translate(EventUpdateTranslate + "ReportToCPA", cultureResolver)} {thirdPartySetting}";
            
            return true;
        }

        bool GetCharges(EventControlDetails ec, string[] cultureResolver, EventUpdateInfo info)
        {
            if (!ec.PayFeeCode.HasValue && !ec.PayFeeCode2.HasValue) return false;

            var hasData = false;
            var translatedCharges = _translator.Translate(EventUpdateTranslate + "RaiseChargeLiteral", cultureResolver);
            var payFeeCode = RatesCodeHelper.StringToRatesCode(ec.PayFeeCode.ToString());
            if (payFeeCode != RatesCode.NotSet)
            {
                info.FeesAndChargesInfo = $"{_eventRulesHelper.RatesCodeToLocalizedString(ec.PayFeeCode, cultureResolver)} {translatedCharges} {ec.ChargeDesc}";
                hasData = true;
            }
            var payFeeCode2 = RatesCodeHelper.StringToRatesCode(ec.PayFeeCode2.ToString());
            if (payFeeCode2 == RatesCode.NotSet) return hasData;
            info.FeesAndChargesInfo2 = $"{_eventRulesHelper.RatesCodeToLocalizedString(ec.PayFeeCode2, cultureResolver)} {translatedCharges} {ec.ChargeDesc2}";
            
            return true;
        }

        bool GetRelatedEventDetails(EventViewRuleDetails details, EventUpdateInfo info, string[] cultureResolver)
        {
            if (details.RelatedEventDetails == null) return false;
            var datesToUpdate = (from ed in details.RelatedEventDetails
                                 where ed.UpdateEvent.GetValueOrDefault()
                                 select new UpdateEventDateItem
                                 {
                                     FormattedDescription = $"{ed.RelatedEventDesc} [{_eventRulesHelper.RelativeCycleToLocalizedString(ed.RelativeCycle, cultureResolver)}]",
                                     Adjustment = ed.Adjustment
                                 }).ToArray();

            var datesToClear = (from ed in details.RelatedEventDetails
                                where ed.ClearEvent.GetValueOrDefault() ||
                                      ed.ClearDue.GetValueOrDefault() ||
                                      ed.ClearEventOnDueChange.GetValueOrDefault() ||
                                      ed.ClearDueOnDueChange.GetValueOrDefault()
                                select ConstructClearDateLocalizedString(ed, cultureResolver)).ToArray();

            info.DatesToUpdate = datesToUpdate.Any() ? datesToUpdate : null;
            info.DatesToClear = datesToClear.Any() ? datesToClear : null;

            return datesToUpdate.Any() || datesToClear.Any();
        }

        string ConstructClearDateLocalizedString(RelatedEventDetails ed, string[] cultureResolver)
        {
            var builder = new StringBuilder();
            builder.Append($"{ed.RelatedEventDesc} [{_eventRulesHelper.RelativeCycleToLocalizedString(ed.RelativeCycle, cultureResolver)}]");
            builder.Append(" - ");
            if (ed.ClearEvent.GetValueOrDefault() || ed.ClearEventOnDueChange.GetValueOrDefault())
            {
                var eventDateString = _eventRulesHelper.DateTypeToLocalizedString((int) DateType.EventDate, cultureResolver);
                builder.Append(eventDateString);
                if (ed.ClearEventOnDueChange.GetValueOrDefault())
                {
                    builder.Append($" {_translator.Translate(EventUpdateTranslate + "DateOperationLiteral", cultureResolver)}");
                }
            }
            else if (ed.ClearDue.GetValueOrDefault() || ed.ClearDueOnDueChange.GetValueOrDefault())
            {
                var dueDateString = _eventRulesHelper.DateTypeToLocalizedString((int) DateType.DueDate, cultureResolver);
                builder.Append(dueDateString);
                if (ed.ClearDueOnDueChange.GetValueOrDefault())
                {
                    builder.Append($" {_translator.Translate(EventUpdateTranslate + "DateOperationLiteral", cultureResolver)}");
                }
            }

            return builder.ToString();
        }
    }
}
