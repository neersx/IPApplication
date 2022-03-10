using System.Linq;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class CaseRelationStepCategory : IStepCategory
    {
        readonly IRelationships _relationships;

        public CaseRelationStepCategory(IRelationships relationships)
        {
            _relationships = relationships;
        }

        public string CategoryType => "relationship";

        public StepCategory Get(TopicControlFilter filter, Criteria criteria = null)
        {
            if (criteria == null) return new StepCategory(CategoryType);

            var relationship = _relationships.Get(criteria.CountryId, criteria.PropertyTypeId, filter.FilterValue)
                                             .Where(r => r.Id == filter.FilterValue)
                                             .Select(_ => new StepPicklistModel<string>
                                                          {
                                                              Key = _.Id,
                                                              Code = _.BaseDescription,
                                                              Value = _.BaseDescription,
                                                              DisplayValue = _.Description
                                                          })
                                             .SingleOrDefault();

            return new StepCategory(CategoryType, relationship);
        }
    }
}