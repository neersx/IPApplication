using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class NameTypeStepCategory : IStepCategory
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public NameTypeStepCategory(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public string CategoryType => "nameType";

        public StepCategory Get(TopicControlFilter filter, Criteria criteria = null)
        {
            var culture = _preferredCultureResolver.Resolve();

            var nameType = _dbContext.Set<NameType>()
                                     .Where(_ => _.NameTypeCode == filter.FilterValue)
                                     .Select(_ => new StepPicklistModel<int>
                                                  {
                                                      Key = _.Id,
                                                      Code = _.NameTypeCode,
                                                      Value = DbFuncs.GetTranslation(null, _.Name, _.NameTId, culture),
                                                      DisplayValue = DbFuncs.GetTranslation(null, _.Name, _.NameTId, culture)
                                                  })
                                     .SingleOrDefault();

            return new StepCategory(CategoryType, nameType);
        }
    }
}