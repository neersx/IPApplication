using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class TextTypeStepCategory : IStepCategory
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public TextTypeStepCategory(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public string CategoryType => "textType";

        public StepCategory Get(TopicControlFilter filter, Criteria criteria = null)
        {
            var culture = _preferredCultureResolver.Resolve();

            var textType = _dbContext.Set<TextType>().Where(_ => _.Id == filter.FilterValue)
                                     .Select(_ => new StepPicklistModel<string>
                                                  {
                                                      Key = _.Id,
                                                      Value = DbFuncs.GetTranslation(string.Empty, _.TextDescription, _.TextDescriptionTId, culture),
                                                      DisplayValue = DbFuncs.GetTranslation(string.Empty, _.TextDescription, _.TextDescriptionTId, culture)
                                                  })
                                     .SingleOrDefault();

            return new StepCategory(CategoryType, textType);
        }
    }
}