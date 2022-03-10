using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class NameGroupStepCategory : IStepCategory
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public NameGroupStepCategory(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public string CategoryType => "nameTypeGroup";

        public StepCategory Get(TopicControlFilter filter, Criteria criteria = null)
        {
            var culture = _preferredCultureResolver.Resolve();

            short id;
            if (!short.TryParse(filter.FilterValue, out id))
                return new StepCategory(CategoryType);

            var nameGroup = _dbContext.Set<NameGroup>().Where(_ => _.Id == id)
                                      .Select(_ => new StepPicklistModel<short>
                                                   {
                                                       Key = _.Id,
                                                       Value = DbFuncs.GetTranslation(null, _.Value, _.NameTId, culture),
                                                       DisplayValue = DbFuncs.GetTranslation(null, _.Value, _.NameTId, culture)
                                                   })
                                      .SingleOrDefault();

            return new StepCategory(CategoryType, nameGroup);
        }
    }
}