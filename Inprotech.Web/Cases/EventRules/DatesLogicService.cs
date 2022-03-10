using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules.Models;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;

namespace Inprotech.Web.Cases.EventRules
{
    public interface IDatesLogicService
    {
        IEnumerable<EventRulesModel.DatesLogicDetailInfo> GetDatesLogicDetails(IEnumerable<DatesLogicDetails> details);
    }

    public class DatesLogicService : IDatesLogicService
    {
        const string DateTranslate = "caseview.eventRules.dateslogic.";
        readonly IEventRulesHelper _eventRuleHelper;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _translator;

        public DatesLogicService(
            IPreferredCultureResolver preferredCultureResolver,
            IStaticTranslator translator,
            IEventRulesHelper eventRuleHelper
        )
        {
            _preferredCultureResolver = preferredCultureResolver;
            _translator = translator;
            _eventRuleHelper = eventRuleHelper;
        }

        public IEnumerable<EventRulesModel.DatesLogicDetailInfo> GetDatesLogicDetails(IEnumerable<DatesLogicDetails> details)
        {
            var datesLogicDetail = new List<EventRulesModel.DatesLogicDetailInfo>();
            var cultureResolver = _preferredCultureResolver.ResolveAll().ToArray();

            foreach (var dd in details)
            {
                var info = new EventRulesModel.DatesLogicDetailInfo();

                var mustExist = dd.MustExist.GetValueOrDefault() ? _translator.Translate(DateTranslate + "mustExist", cultureResolver) : string.Empty;

                var dateComparison = $"{dd.CompareEventDesc} [{_eventRuleHelper.RelativeCycleToLocalizedString(dd.RelativeCycle, cultureResolver)}] {_eventRuleHelper.DateTypeToLocalizedString(dd.CompareDateType, cultureResolver)}".MakeSentenceLike();

                var fromRelationshipClause = string.IsNullOrWhiteSpace(dd.CompareRelationship) ? string.Empty : 
                    string.Format(_translator.Translate(DateTranslate + "fromRelationship", cultureResolver), "\"" + dd.CompareRelationship + "\"", mustExist).MakeSentenceLike();

                info.FormattedDescription = string.Format(_translator.Translate(DateTranslate + "dateValidation", cultureResolver),
                                                          _eventRuleHelper.DateTypeToLocalizedString(dd.DateType, cultureResolver),
                                                          _eventRuleHelper.ComparisonOperatorToSymbol(dd.Operator, cultureResolver), dateComparison, fromRelationshipClause).MakeSentenceLike();

                var failureAction = FailureActionHelper.ToFailureAction(dd.DisplayErrorFlag);
                if (failureAction != FailureAction.NotSet)
                {
                    info.TestFailureAction = _translator.Translate(DateTranslate + "failureAction_" + failureAction, cultureResolver);
                    info.MessageDisplayed = dd.ErrorMessage;
                    info.FailureActionType = failureAction.ToString();
                }

                datesLogicDetail.Add(info);
            }

            return datesLogicDetail;
        }
    }
}