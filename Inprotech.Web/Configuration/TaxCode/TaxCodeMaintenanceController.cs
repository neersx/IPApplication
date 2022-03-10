using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.TaxCode
{
    [Authorize]
    [RoutePrefix("api/configuration/tax-codes")]
    [RequiresAccessTo(ApplicationTask.MaintainTaxCodes)]
    public class TaxCodeMaintenanceController : ApiController
    {
        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "TaxCode",
                SortDir = "asc"
            });

        readonly IDbContext _dbContext;

        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ITaxCodeDetailService _taxCodeDetailService;
        readonly ITaxCodeMaintenanceService _taxCodeMaintenanceService;
        readonly ITaxCodeSearchService _taxSearchService;

        public TaxCodeMaintenanceController(ITaxCodeSearchService taxSearchService, IPreferredCultureResolver preferredCultureResolver, ITaskSecurityProvider taskSecurityProvider,
                                            ITaxCodeMaintenanceService taxCodeMaintenanceService, ITaxCodeDetailService taxCodeDetailService, IDbContext dbContext)
        {
            _taxSearchService = taxSearchService;
            _preferredCultureResolver = preferredCultureResolver;
            _taskSecurityProvider = taskSecurityProvider;
            _taxCodeMaintenanceService = taxCodeMaintenanceService;
            _taxCodeDetailService = taxCodeDetailService;
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("viewdata")]
        [RequiresAccessTo(ApplicationTask.MaintainTaxCodes, ApplicationTaskAccessLevel.None)]
        [NoEnrichment]
        public dynamic GetViewData()
        {
            return new TaxCodePermissionsData
            {
                CanDeleteTaxCode = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaxCodes, ApplicationTaskAccessLevel.Delete),
                CanUpdateTaxCode = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaxCodes, ApplicationTaskAccessLevel.Modify),
                CanCreateTaxCode = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaxCodes, ApplicationTaskAccessLevel.Create)
            };
        }

        [HttpGet]
        [Route("search")]
        [RequiresAccessTo(ApplicationTask.MaintainTaxCodes, ApplicationTaskAccessLevel.None)]
        [NoEnrichment]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                              CommonQueryParameters queryParameters = null)
        {
            var details = new TaxCodeDetails();
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var culture = _preferredCultureResolver.Resolve();
            var taxCodes = _taxSearchService.DoSearch(searchOptions, culture).AsEnumerable();

            taxCodes = taxCodes.OrderByProperty(queryParameters.SortBy,
                                                queryParameters.SortDir);
            details.TaxCodes = taxCodes;
            details.Ids = details.TaxCodes.Select(x => x.Id);
            return details;
        }

        [HttpPost]
        [Route("delete")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainTaxCodes, ApplicationTaskAccessLevel.Delete)]
        public async Task<DeleteResponseModel> Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            return await _taxCodeMaintenanceService.Delete(deleteRequestModel);
        }

        [HttpPost]
        [Route("create")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainTaxCodes, ApplicationTaskAccessLevel.Create)]
        public async Task<dynamic> CreateTaxCode(TaxCodes taxCodes)
        {
            return await _taxCodeMaintenanceService.CreateTaxCode(taxCodes);
        }

        [HttpGet]
        [Route("overview-details/{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainTaxCodes, ApplicationTaskAccessLevel.None)]
        [NoEnrichment]
        public async Task<TaxCodes> GetTaxCodeDetails(int id)
        {
            var culture = _preferredCultureResolver.Resolve();
            return await _taxCodeDetailService.GetTaxCodeDetails(id, culture);
        }

        [HttpGet]
        [Route("tax-rate-details/{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainTaxCodes, ApplicationTaskAccessLevel.None)]
        [NoEnrichment]
        public async Task<TaxRates[]> GetTaxRateDetails(int id)
        {
            var culture = _preferredCultureResolver.Resolve();
            return await _taxCodeDetailService.GetTaxRateDetails(id, culture);
        }

        [HttpPost]
        [Route("update")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainTaxCodes, ApplicationTaskAccessLevel.Modify)]
        public async Task<DeleteResponseModel> MaintainTaxCodeDetails(TaxCodeSaveDetails taxCodeSaveDetails)
        {
            if (taxCodeSaveDetails == null)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            var taxCode = _dbContext.Set<TaxRate>().SingleOrDefault(_ => _.Id == taxCodeSaveDetails.OverviewDetails.Id);
            if (taxCode == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            return await _taxCodeMaintenanceService.MaintainTaxCodeDetails(taxCodeSaveDetails);
        }
    }

    public class TaxCodePermissionsData
    {
        public bool CanDeleteTaxCode { get; set; }
        public bool CanUpdateTaxCode { get; set; }
        public bool CanCreateTaxCode { get; set; }
    }
}