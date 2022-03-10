using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Picklists;
using static Inprotech.Web.Picklists.ExchangeRateSchedulePicklistController;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Web.Configuration.ExchangeRateSchedule
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/exchange-rate-schedule")]
    [RequiresAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.None)]
    public class ExchangeRateScheduleController : ApiController
    {
        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "code",
                SortDir = "asc"
            });

        readonly IExchangeRateScheduleService _exchangeRateScheduleService;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public ExchangeRateScheduleController(ITaskSecurityProvider taskSecurityProvider, IExchangeRateScheduleService exchangeRateScheduleService)
        {
            _exchangeRateScheduleService = exchangeRateScheduleService;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            return new
            {
                CanAdd = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Create),
                CanDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Delete),
                CanEdit = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Modify)
            };
        }

        [HttpGet]
        [Route("")]
        public async Task<PagedResults> GetExchangeRateSchedule(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
            SearchOptions searchOptions,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters qp)
        {
            var queryParameters = DefaultQueryParameters.Extend(qp);
            var all = await _exchangeRateScheduleService.GetExchangeRateSchedule();

            if (!string.IsNullOrEmpty(searchOptions?.Text))
            {
                all = all.Where(_ => _.Description.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1 || _.Code.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            var result = Helpers.GetPagedResults(all, queryParameters, x => x.Id.ToString(), x => x.Id.ToString(), searchOptions.Text);
            result.Ids = result.Data.Select(_ => _.Id);
            return result;
        }

        [HttpGet]
        [Route("validate/{code}")]
        public async Task<ValidationError> ValidateExistingCode(string code)
        {
            if(string.IsNullOrWhiteSpace(code)) throw new ArgumentNullException(code);
            return await _exchangeRateScheduleService.ValidateExistingCode(code);
        }

        [HttpGet]
        [Route("{id:int}")]
        public async Task<ExchangeRateSchedulePicklistItem> GetExchangeRateScheduleDetails(int id)
        {
            return await _exchangeRateScheduleService.GetExchangeRateScheduleDetails(id);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Create)]
        public async Task<dynamic> AddExchangeRateSchedule(ExchangeRateSchedulePicklistItem request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _exchangeRateScheduleService.SubmitExchangeRateSchedule(request);
        }

        [HttpPut]
        [Route("{id:int}")]
        [RequiresAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> UpdateExchangeRateSchedule(ExchangeRateSchedulePicklistItem request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _exchangeRateScheduleService.SubmitExchangeRateSchedule(request);
        }

        [HttpDelete]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Delete)]
        public async Task<dynamic> DeleteExchangeRateSchedules(DeleteRequestModel request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _exchangeRateScheduleService.Delete(request);
        }
    }
}