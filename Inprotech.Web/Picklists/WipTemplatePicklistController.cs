using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using Newtonsoft.Json;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/wiptemplates")]
    public class WipTemplatePicklistController : ApiController
    {
        readonly ICommonQueryService _commonQueryService;
        readonly IWipTemplateMatcher _wipTemplateMatcher;

        public WipTemplatePicklistController(ICommonQueryService commonQueryService, IWipTemplateMatcher wipTemplateMatcher)
        {
            _commonQueryService = commonQueryService;
            _wipTemplateMatcher = wipTemplateMatcher;
        }
        
        [HttpGet]
        [RequiresCaseAuthorization()]
        [Route]
        public async Task<PagedResults<WipTemplatePicklistItem>> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                    CommonQueryParameters queryParameters = null, string search = "", bool isTimesheetActivity = true, int? caseId = null, bool onlyDisbursements = false)
        {
            if (queryParameters != null && queryParameters.Filters.Any())
            {
                queryParameters.RemapFilter("type", "typeid");
            }

            var all = _commonQueryService.Filter(await _wipTemplateMatcher.Get(search, isTimesheetActivity, caseId, onlyDisbursements), queryParameters);
            return Helpers.GetPagedResults(all, queryParameters, x => x.Key.ToString(), x => x.Value, search);
        }

        [HttpGet]
        [Route("filterData/{field}")]
        public async Task<IEnumerable<object>> GetFilterDataForColumn(string search, bool isTimesheetActivity = true, bool onlyDisbursements = false)
        {
            return GetFilterData(await _wipTemplateMatcher.Get(search, isTimesheetActivity, null, onlyDisbursements));
        }

        static IEnumerable<object> GetFilterData(IEnumerable<WipTemplatePicklistItem> result)
        {
            var r = result.OrderBy(_ => _.Type)
                          .Select(__ => new
                          {
                              Code = __.TypeId, 
                              Description = !string.IsNullOrEmpty(__.Type) ? __.Type : "[null]"
                          })
                          .Distinct();
            return r;
        }
    }

    public class WipTemplatePicklistItem
    {
        [PicklistKey]
        public string Key { get; set; }

        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        [PicklistColumn(filterable: true, filterApi: "api/picklists/wiptemplates", filterType: FilterTypes.Text)]
        public string Type { get; set; }

        public string TypeId { get; set; }

        [JsonIgnore]
        public string CaseTypeId { get; set; }

        [JsonIgnore]
        public string PropertyTypeId { get; set; }

        [JsonIgnore]
        public string CountryCode { get; set; }

        [JsonIgnore]
        public string ActionId { get; set; }

        [JsonIgnore]
        public short? UsedBy { get; set; }

        [JsonIgnore]
        public string WipTypeCategoryId { get; set; }
    }
}