using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/profitcentre")]
    public class ProfitCentrePicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ICommonQueryService _commonQueryService;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public ProfitCentrePicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ICommonQueryService commonQueryService)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _commonQueryService = commonQueryService;
        }

        [HttpGet]
        [Route]
        public async Task<PagedResults<ProfitCentrePicklistItem>> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                           CommonQueryParameters queryParameters = null, string search = "")
        {
            var results = _commonQueryService.Filter(await GetData(search), queryParameters);

            return Helpers.GetPagedResults(results,
                                           queryParameters,
                                           x => x.Code, x => x.Description, search);
        }

        public async Task<IEnumerable<ProfitCentrePicklistItem>> GetData(string search)
        {
            var query = search ?? string.Empty;
            var culture = _preferredCultureResolver.Resolve();

            var interimResult = from p in _dbContext.Set<ProfitCentre>()
                                let description = DbFuncs.GetTranslation(p.Name, null, null, culture)
                                where description.ToLower().Contains(query) || p.Id.ToLower().Contains(query)
                                select new
                                {
                                    p.Id,
                                    Description = description,
                                    Entity = p.EntityName
                                };

            return from r in await interimResult.ToArrayAsync()
                          let isContains = r.Id.IgnoreCaseContains(query) || r.Description.IgnoreCaseContains(query)
                          let isStartsWith = r.Id.IgnoreCaseStartsWith(query) || r.Description.IgnoreCaseStartsWith(query)
                          let entityName = r.Entity.FormattedNameOrNull()
                          orderby isStartsWith descending, isContains descending, entityName
                          select new ProfitCentrePicklistItem
                          {
                              Code = r.Id,
                              EntityName = entityName,
                              Description = r.Description
                          };
        }

        [HttpGet]
        [Route("filterData/{field}")]
        public async Task<IEnumerable<object>> GetFilterDataForColumn(string search)
        {
            return GetFilterData(await GetData(search));
        }

        static IEnumerable<object> GetFilterData(IEnumerable<ProfitCentrePicklistItem> result)
        {
            var r = result.OrderBy(_ => _.EntityName)
                          .Select(__ => new {Code = __.EntityName, Description = __.EntityName})
                          .Distinct();
            return r;
        }

        public class ProfitCentrePicklistItem
        {
            [PicklistKey]
            public string Code { get; set; }
            [PicklistDescription]
            public string Description { get; set; }
            public string EntityName { get; set; }
        }
    }
}