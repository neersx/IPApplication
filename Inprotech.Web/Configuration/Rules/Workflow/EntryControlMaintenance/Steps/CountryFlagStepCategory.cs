using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class CountryFlagStepCategory : IStepCategory
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public CountryFlagStepCategory(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public string CategoryType => "designationStage";

        public StepCategory Get(TopicControlFilter filter, Criteria criteria = null)
        {
            int flag;
            if (!int.TryParse(filter.FilterValue, out flag) || criteria == null)
                return new StepCategory(CategoryType);

            var culture = _preferredCultureResolver.Resolve();

            var countryFlag = _dbContext.Set<CountryFlag>()
                                        .Where(_ => _.CountryId == criteria.CountryId && _.FlagNumber == flag)
                                        .Select(_ => new StepPicklistModel<int>
                                                     {
                                                         Key = _.FlagNumber,
                                                         Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                                         DisplayValue = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
                                                     })
                                        .SingleOrDefault();

            return new StepCategory(CategoryType, countryFlag);
        }
    }
}