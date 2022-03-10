using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using static Inprotech.Web.Configuration.Currencies.CurrenciesService;

namespace Inprotech.Web.Configuration.Currencies
{
    public interface ICurrencies
    {
        Task<CurrencyModel> GetCurrencyDetails(string code);
        Task<ValidationError> ValidateExistingCode(string code);
        Task<string> SubmitCurrency(CurrencyModel model);
        Task<CurrenciesDeleteResponseModel> DeleteCurrencies(CurrenciesDeleteRequestModel deleteRequestModel);
    }

    public class CurrenciesService : ICurrencies
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        public CurrenciesService(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public async Task<CurrenciesDeleteResponseModel> DeleteCurrencies(CurrenciesDeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null || !deleteRequestModel.Ids.Any()) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new CurrenciesDeleteResponseModel();

            var currencies = _dbContext.Set<Currency>().Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

            foreach (var currency in currencies)
            {
                using (var txScope = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
                {
                    try
                    {
                        foreach (var history in _dbContext.Set<ExchangeRateHistory>().Where(_ => _.Id == currency.Id).ToArray())
                        {
                            _dbContext.Set<ExchangeRateHistory>().Remove(history);
                        }
                        await _dbContext.SaveChangesAsync();

                        _dbContext.Set<Currency>().Remove(currency);
                        await _dbContext.SaveChangesAsync();
                        txScope.Complete();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(currency.Id);
                        }

                        _dbContext.Detach(currency);
                    }
                }
            }

            if (!response.InUseIds.Any()) return response;
            response.HasError = true;
            response.Message = ConfigurationResources.InUseErrorMessage;

            return response;
        }

        public class CurrenciesDeleteRequestModel
        {
            public List<string> Ids { get; set; }
        }

        public class CurrenciesDeleteResponseModel
        {
            public CurrenciesDeleteResponseModel()
            {
                InUseIds = new List<string>();
            }

            public List<string> InUseIds { get; set; }
            public bool HasError { get; set; }
            public string Message { get; set; }
        }

        public async Task<CurrencyModel> GetCurrencyDetails(string code)
        {
            var culture = _preferredCultureResolver.Resolve();
            var result = await _dbContext.Set<Currency>()
                                           .Where(x => x.Id == code)
                                           .Select(x => new CurrencyModel()
                                           {
                                               Id = x.Id,
                                               CurrencyCode = x.Id,
                                               CurrencyDescription = DbFuncs.GetTranslation(x.Description, null, x.DescriptionTId, culture),
                                               BankRate = x.BankRate,
                                               DateChanged = x.DateChanged,
                                               SellFactor = x.SellFactor,
                                               SellRate = x.SellRate,
                                               BuyRate = x.BuyRate,
                                               BuyFactor = x.BuyFactor,
                                               RoundedBillValues = x.RoundBillValues
                                           }).FirstOrDefaultAsync();

            if (result == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            return result;
        }

        public async Task<string> SubmitCurrency(CurrencyModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var currency = await _dbContext.Set<Currency>().FirstOrDefaultAsync(x => x.Id == model.Id);
            if (currency != null)
            {
                currency.Description = model.CurrencyDescription;
                currency.BankRate = model.BankRate;
                currency.RoundBillValues = model.RoundedBillValues;
                currency.BuyFactor = model.BuyFactor;
                currency.BuyRate = model.BuyRate;
                currency.SellRate = model.SellRate;
                currency.SellFactor = model.SellFactor;
                currency.DateChanged = model.DateChanged;
            }
            else
            {
                currency = new Currency
                {
                    Id = model.Id,
                    Description = model.CurrencyDescription,
                    BankRate = model.BankRate,
                    RoundBillValues = model.RoundedBillValues,
                    BuyFactor = model.BuyFactor,
                    BuyRate = model.BuyRate,
                    SellRate = model.SellRate,
                    SellFactor = model.SellFactor,
                    DateChanged = model.DateChanged
                };
                _dbContext.Set<Currency>().Add(currency);
            }

            var exchangeRate = await _dbContext.Set<ExchangeRateHistory>().FirstOrDefaultAsync(x => x.Id == model.Id
                                                                                                    && x.DateChanged.Year == model.DateChanged.Value.Year
                                                                                                    && x.DateChanged.Month == model.DateChanged.Value.Month
                                                                                                    && x.DateChanged.Day == model.DateChanged.Value.Day);

            if (exchangeRate != null)
            {
                exchangeRate.BankRate = model.BankRate;
                exchangeRate.BuyFactor = model.BuyFactor;
                exchangeRate.BuyRate = model.BuyRate;
                exchangeRate.SellRate = model.SellRate;
                exchangeRate.SellFactor = model.SellFactor;
            }
            else
            {
                exchangeRate = new ExchangeRateHistory(currency);
                _dbContext.Set<ExchangeRateHistory>().Add(exchangeRate);
            }

            await _dbContext.SaveChangesAsync();
            return model.Id;
        }

        public async Task<ValidationError> ValidateExistingCode(string code)
        {
            var allCodes = await _dbContext.Set<Currency>().ToListAsync();

            if (allCodes.Any(_ => _.Id == code))
            {
                return ValidationErrors.SetCustomError("currencyCode",
                                                       "field.errors.duplicateCurrencyCode", null, true);
            }

            return null;
        }
    }

    public class CurrencyModel
    {
        public string Id { get; set; }
        public string CurrencyCode { get; set; }
        public string CurrencyDescription { get; set; }
        public decimal? BankRate { get; set; }
        public DateTime? DateChanged { get; set; }
        public decimal? BuyRate { get; set; }
        public decimal? BuyFactor { get; set; }
        public decimal? SellRate { get; set; }
        public decimal? SellFactor { get; set; }
        public short? RoundedBillValues { get; set; }
    }
}