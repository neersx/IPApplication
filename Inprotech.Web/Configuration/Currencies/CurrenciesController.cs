using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using static Inprotech.Web.Configuration.Currencies.CurrenciesService;
using Currency = InprotechKaizen.Model.Cases.Currency;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Web.Configuration.Currencies
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/currencies")]
    [RequiresAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.None)]
    public class CurrenciesController : ApiController
    {
        readonly ICurrencies _currenciesService;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _queryParameters;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public CurrenciesController(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider, IPreferredCultureResolver preferredCultureResolver, ICurrencies currenciesService)
        {
            _currenciesService = currenciesService;
            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _queryParameters = new CommonQueryParameters {SortBy = "Id"};
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            return new
            {
                CanAdd = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Create),
                CanDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Delete),
                CanEdit = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Modify)
            };
        }

        [HttpGet]
        [Route("")]
        public PagedResults GetCurrencies([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                          SearchOptions searchOptions,
                                          [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                          CommonQueryParameters queryParameters = null)
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(searchOptions?.Text));
            var culture = _preferredCultureResolver.Resolve();

            var exchangeRateHistory = _dbContext.Set<ExchangeRateHistory>().GroupBy(x => x.Id).Select(_ => _.FirstOrDefault()).Select(_ => _.Id).Distinct();
            var result = (from c in _dbContext.Set<Currency>()
                          join ex in exchangeRateHistory on c.Id equals ex into ex1
                          from ex in ex1.DefaultIfEmpty()
                          select new
                          {
                              c.Id,
                              CurrencyCode = c.Id,
                              CurrencyDescription = DbFuncs.GetTranslation(c.Description, null, c.DescriptionTId, culture) ?? string.Empty,
                              HasHistory = ex != null,
                              c.BankRate,
                              EffectiveDate = c.DateChanged,
                              c.BuyFactor,
                              c.BuyRate,
                              c.SellFactor,
                              c.SellRate
                          }).AsEnumerable();

            if (searchOptions != null && !string.IsNullOrWhiteSpace(searchOptions.Text))
            {
                result = result.Where(_ =>
                                          string.Equals(_.CurrencyCode, searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) ||
                                          _.CurrencyCode.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1 ||
                                          _.CurrencyDescription.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            var data = Helpers.GetPagedResults(result, extendedQueryParams,
                                               x => x.CurrencyCode, x => x.CurrencyDescription, searchOptions?.Text);

            return data;
        }

        [HttpGet]
        [Route("{code}")]
        public async Task<CurrencyModel> GetCurrencyDetails(string code)
        {
            return await _currenciesService.GetCurrencyDetails(code);
        }

        [HttpGet]
        [Route("validate/{code}")]
        public async Task<ValidationError> ValidateCurrencyCode(string code)
        {
            return await _currenciesService.ValidateExistingCode(code);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Create)]
        public async Task<dynamic> AddCurrency(CurrencyModel request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _currenciesService.SubmitCurrency(request);
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> UpdateCurrency(CurrencyModel request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _currenciesService.SubmitCurrency(request);
        }

        [HttpDelete]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Delete)]
        public async Task<dynamic> DeleteCurrencies(CurrenciesDeleteRequestModel request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _currenciesService.DeleteCurrencies(request);
        }

        [HttpGet]
        [Route("history/{id}")]
        public PagedResults GetExchangeRateHistory(string id, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                   CommonQueryParameters queryParameters = null)
        {
            if (string.IsNullOrWhiteSpace(id)) throw new ArgumentNullException(nameof(id));

            var defaultQp = new CommonQueryParameters {SortBy = "EffectiveDate", SortDir = "desc"};
            var extendedQueryParams = defaultQp.Extend(queryParameters);
            var results = _dbContext.Set<ExchangeRateHistory>().Where(_ => _.Id == id).Select(_ => new
            {
                _.Id,
                EffectiveDate = _.DateChanged,
                _.BankRate,
                _.BuyFactor,
                _.BuyRate,
                _.SellFactor,
                _.SellRate
            });

            return Helpers.GetPagedResults(results, extendedQueryParams, x => x.Id, x => x.Id, null);
        }

        [HttpGet]
        [Route("currency-desc/{id}")]
        public async Task<string> GetCurrencyDesc(string id)
        {
            if (string.IsNullOrWhiteSpace(id)) throw new ArgumentNullException(nameof(id));
            var culture = _preferredCultureResolver.Resolve();
            return await _dbContext.Set<Currency>().Where(_ => _.Id == id).Select(c => DbFuncs.GetTranslation(c.Description, null, c.DescriptionTId, culture)).FirstOrDefaultAsync();
        }
    }
}