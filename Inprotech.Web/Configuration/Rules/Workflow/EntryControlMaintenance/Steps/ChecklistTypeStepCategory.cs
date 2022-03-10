using System.Linq;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class ChecklistTypeStepCategory : IStepCategory
    {
        readonly IChecklists _checklists;

        public ChecklistTypeStepCategory(IChecklists checklists)
        {
            _checklists = checklists;
        }

        public string CategoryType => "checklist";

        public StepCategory Get(TopicControlFilter filter, Criteria criteria = null)
        {
            short checklistTypeKey;
            if (!short.TryParse(filter.FilterValue, out checklistTypeKey) || criteria == null)
                return new StepCategory(CategoryType);

            var checklist = _checklists.Get(criteria.CountryId, criteria.PropertyTypeId, criteria.CaseTypeId, checklistTypeKey)
                                       .Where(c => c.Id == checklistTypeKey)
                                       .Select(c => new StepPicklistModel<short>
                                                    {
                                                        Key = c.Id,
                                                        Code = c.BaseDescription,
                                                        Value = c.BaseDescription,
                                                        DisplayValue = c.Description
                                                    })
                                       .SingleOrDefault();
            
            return new StepCategory(CategoryType, checklist);
        }
    }
}