using System;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Picklists;

namespace Inprotech.Web.Configuration.ExchangeRateVariations
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/exchange-rate-variation")]
    [RequiresAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.None)]
    [RequiresAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.None)]
    public class ExchangeRateVariationController : ApiController
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IExchangeRateVariations _exchangeRateVariations;
        readonly CommonQueryParameters _queryParameters;
        const string ExchangeRateScheduleType = "EXS";

        public ExchangeRateVariationController(ITaskSecurityProvider taskSecurityProvider, IExchangeRateVariations exchangeRateVariations)
        {
            _taskSecurityProvider = taskSecurityProvider;
            _exchangeRateVariations = exchangeRateVariations;
            _queryParameters = new CommonQueryParameters { SortBy = "Currency" };
        }

        [HttpGet]
        [Route("permissions/{type:maxlength(3)?}")]
        [NoEnrichment]
        public dynamic ViewData(string type)
        {

            if (type == ExchangeRateScheduleType)
            {
                return new
                {
                    CanAdd = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Create),
                    CanDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Delete),
                    CanEdit = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Modify)
                };
            }
            return new
            {
                CanAdd = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Create),
                CanDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Delete),
                CanEdit = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Modify)
            };
        }

        [HttpGet]
        [Route("")]
        public PagedResults GetExchangeRateVariations([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                          ExchangeRateVariationsFilterModel filter,
                                          [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                          CommonQueryParameters queryParameters = null)
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters);
            var results = _exchangeRateVariations.GetExchangeRateVariations(filter);

            return Helpers.GetPagedResults(results, extendedQueryParams, null, null, null);
        }

        [HttpGet]
        [Route("{id:int}")]
        public async Task<ExchangeRateVariationModel> GetExchangeRateVariationDetails(int id)
        {
            return await _exchangeRateVariations.GetExchangeRateVariationDetails(id);
        }

        [HttpPost]
        [Route("validate")]
        public async Task<Infrastructure.Validations.ValidationError> ValidateDuplicateExchangeVariation(ExchangeRateVariationRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _exchangeRateVariations.ValidateDuplicateExchangeVariation(request);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Create)]
        [RequiresAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Create)]
        public async Task<dynamic> AddExchangeRateVariation(ExchangeRateVariationRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _exchangeRateVariations.SubmitExchangeRateVariation(request);
        }

        [HttpPut]
        [Route("{id:int}")]
        [RequiresAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Modify)]
        [RequiresAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> UpdateExchangeRateVariation(ExchangeRateVariationRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _exchangeRateVariations.SubmitExchangeRateVariation(request);
        }

        [HttpDelete]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Delete)]
        public async Task<DeleteResponseModel> Delete(DeleteRequestModel request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _exchangeRateVariations.Delete(request);
        }
    }
}
