using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class NumberTypeStepCategory : IStepCategory
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public NumberTypeStepCategory(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public string CategoryType => "numberType";

        public StepCategory Get(TopicControlFilter filter, Criteria criteria = null)
        {
            var culture = _preferredCultureResolver.Resolve();

            var numberType = _dbContext.Set<NumberType>()
                                       .Where(_ => _.NumberTypeCode == filter.FilterValue)
                                       .Select(_ => new StepPicklistModel<string>
                                                    {
                                                        Key = _.NumberTypeCode,
                                                        Value = DbFuncs.GetTranslation(string.Empty, _.Name, _.NameTId, culture),
                                                        DisplayValue = DbFuncs.GetTranslation(string.Empty, _.Name, _.NameTId, culture)
                                                    })
                                       .SingleOrDefault();

            return new StepCategory(CategoryType, numberType);
        }
    }
}