using System.Collections.Generic;
using System.Data.Entity;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using System.Linq;
using System.Threading.Tasks;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Cases
{
    public interface ICaseDataExtension
    {
        Task<Dictionary<int, CaseData>> GetPropertyTypeAndCountry(int[] caseIds, string culture);
        Task<ActionData> GetValidAction(ValidActionIdentifier validActionIdentifier, string culture);
    }

    public class CaseDataExtension : ICaseDataExtension
    {
        readonly IDbContext _dbContext;

        public CaseDataExtension(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<Dictionary<int, CaseData>> GetPropertyTypeAndCountry(int[] caseIds, string culture)
        {

            var vp = _dbContext.Set<ValidProperty>();

            var data = from cases in _dbContext.Set<Case>().Where(_ => caseIds.Contains(_.Id))
                       join country in _dbContext.Set<Country>() on cases.CountryId equals country.Id into ct1
                       from country in ct1.DefaultIfEmpty()
                       join validProperty in _dbContext.Set<ValidProperty>() on new
                       {
                           cases.PropertyTypeId,
                           CountryId = vp
                                           .Where(_ => _.PropertyTypeId == cases.PropertyTypeId && new[] { cases.CountryId, KnownValues.DefaultCountryCode }.Contains(_.CountryId))
                                           .Select(_ => _.CountryId)
                                           .Min()
                       }
                           equals new { validProperty.PropertyTypeId, validProperty.CountryId } into validProperties
                       from valProperties in validProperties.DefaultIfEmpty()
                       where caseIds.Contains(cases.Id)
                       select new CaseData
                       {
                           CaseId = cases.Id,
                           Country = country != null ? DbFuncs.GetTranslation(country.Name, null, country.NameTId, culture) : null,
                           PropertyTypeDescription = valProperties != null ? DbFuncs.GetTranslation(valProperties.PropertyName, null, valProperties.PropertyNameTId, culture) : null
                       };

            return await data.ToDictionaryAsync(x => x.CaseId, caseData => caseData);
        }

        public async Task<ActionData> GetValidAction(ValidActionIdentifier validActionIdentifier, string culture)
        {
            if (string.IsNullOrWhiteSpace(validActionIdentifier.ActionCode)) return null;

            return await (from va in _dbContext.Set<ValidAction>()
                          where va.CountryId == validActionIdentifier.CountryCode && va.PropertyTypeId == validActionIdentifier.PropertyTypeCode &&
                                va.CaseTypeId == validActionIdentifier.CaseTypeCode && va.ActionId == validActionIdentifier.ActionCode
                          select new ActionData
                          {
                              Key = va.Action.Id,
                              Code = va.ActionId,
                              Value = DbFuncs.GetTranslation(va.ActionName, null, va.ActionNameTId, culture)
                          }).FirstOrDefaultAsync();
        }
    }

    public class ActionData
    {        
        public int Key { get; set; }
        public string Code { get; set; }
        public string Value { get; set; }
    }

    public class ValidActionIdentifier
    {
        public string CaseTypeCode { get; set; }
        public string PropertyTypeCode { get; set; }
        public string CountryCode { get; set; }
        public string ActionCode { get; set; }
    }
}
