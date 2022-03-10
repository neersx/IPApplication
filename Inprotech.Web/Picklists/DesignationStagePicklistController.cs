using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/designationstage")]
    public class DesignationStagePicklistController : ApiController
    {
        readonly IPreferredCultureResolver _culture;
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;

        public DesignationStagePicklistController(IDbContext dbContext, IPreferredCultureResolver culture)
        {
            _dbContext = dbContext;
            _culture = culture;
            _queryParameters = new CommonQueryParameters
                               {
                                   SortBy = "Key"
                               };
        }

        [HttpGet]
        [Route]
        public PagedResults Get([ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "", string jurisdictionId = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            
            var culture = _culture.Resolve();

            var all = (from flags in _dbContext.Set<CountryFlag>()
                       join jurisdiction in _dbContext.Set<Country>() on flags.CountryId equals jurisdiction.Id into j1
                       from jurisdiction in j1.DefaultIfEmpty()
                       where jurisdictionId != null && flags.CountryId == jurisdictionId
                       select new DesignationStage
                              {
                                  Value = DbFuncs.GetTranslation(flags.Name, null, flags.NameTId, culture),
                                  Key = flags.FlagNumber,
                                  Jurisdiction = DbFuncs.GetTranslation(jurisdiction.Name, null, jurisdiction.NameTId, culture),
                                  JurisdictionId = jurisdiction.Id
                              }).ToArray();

            var result = string.IsNullOrWhiteSpace(search) ? all : all.Where(_ => _.Value.IndexOf(search, StringComparison.CurrentCultureIgnoreCase) > -1);

            return Helpers.GetPagedResults(result, extendedQueryParams, x => x.Key.ToString(), x => x.Value, search);
        }

        public class DesignationStage
        {
            public string Value { get; set; }

            public string Jurisdiction { get; set; }

            public int Key { get; set; }

            public string JurisdictionId { get; set; }
        }
    }
}