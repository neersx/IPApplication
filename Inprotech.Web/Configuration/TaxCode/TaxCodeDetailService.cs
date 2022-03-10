using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.TaxCode
{
    public interface ITaxCodeDetailService
    {
        public Task<TaxCodes> GetTaxCodeDetails(int id, string culture);
        public Task<TaxRates[]> GetTaxRateDetails(int id, string culture);
    }

    public class TaxCodeDetailService : ITaxCodeDetailService
    {
        readonly IDbContext _dbContext;

        public TaxCodeDetailService(IDbContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        }

        public async Task<TaxCodes> GetTaxCodeDetails(int id, string culture)
        {
            var overviewDetails = await _dbContext.Set<TaxRate>()
                                                  .Where(_ => _.Id == id)
                                                  .Select(_ => new TaxCodes
                                                  {
                                                      Id = _.Id,
                                                      Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture),
                                                      TaxCode = _.Code
                                                  }).SingleOrDefaultAsync();

            return overviewDetails;
        }

        public async Task<TaxRates[]> GetTaxRateDetails(int id, string culture)
        {
            var taxCode = _dbContext.Set<TaxRate>().SingleOrDefault(_ => _.Id == id);
            var taxRateCountries = from tr in _dbContext.Set<TaxRatesCountry>().Where(_ => _.TaxCode == taxCode.Code)
                                   join ct in _dbContext.Set<Country>() on tr.CountryId equals ct.Id
                                   orderby ct.Name
                                   select new TaxRates
                                   {
                                       Id = tr.TaxRateCountryId,
                                       EffectiveDate = tr.EffectiveDate,
                                       SourceJurisdiction = new SourceJurisdiction
                                       {
                                           Key = ct.Id == KnownValues.DefaultCountryCode ? string.Empty : ct.Id,
                                           Value = ct.Id == KnownValues.DefaultCountryCode ? string.Empty : DbFuncs.GetTranslation(ct.Name, null, ct.NameTId, culture),
                                           Code = ct.Id == KnownValues.DefaultCountryCode ? string.Empty : ct.Name
                                       },
                                       TaxRate = tr.Rate.ToString()
                                   };

            return await taxRateCountries.OrderBy(x => x.SourceJurisdiction.Code).ToArrayAsync();
        }
    }

    public class SourceJurisdiction
    {
        public string Code { get; set; }
        public string Value { get; set; }
        public string Key { get; set; }
    }
}