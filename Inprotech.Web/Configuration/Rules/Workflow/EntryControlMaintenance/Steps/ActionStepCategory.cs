using System.Linq;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class ActionStepCategory : IStepCategory
    {
        readonly IActions _actions;

        public ActionStepCategory(IActions actions)
        {
            _actions = actions;
        }

        public string CategoryType => "action";

        public StepCategory Get(TopicControlFilter filter, Criteria criteria = null)
        {
            if (criteria == null) return new StepCategory(CategoryType);

            var action = _actions.Get(criteria.CountryId, criteria.PropertyTypeId, criteria.CaseTypeId, filter.FilterValue)
                                 .Where(a => a.Code == filter.FilterValue)
                                 .Select(_ => new StepPicklistModel<string>
                                              {
                                                  Key = _.Code,
                                                  Code = _.BaseName,
                                                  Value = _.BaseName,
                                                  DisplayValue = _.Name
                                              })
                                 .SingleOrDefault();

            return new StepCategory(CategoryType, action);
        }
    }
}