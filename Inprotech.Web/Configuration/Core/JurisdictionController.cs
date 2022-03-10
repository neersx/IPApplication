using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [NoEnrichment]
    public class JurisdictionController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _cultureResolver;
        readonly CommonQueryParameters _queryParameters;

        public JurisdictionController(IDbContext dbContext, IPreferredCultureResolver cultureResolver)
        {
            _dbContext = dbContext;
            _cultureResolver = cultureResolver;
            _queryParameters = new CommonQueryParameters { SortBy = "Description" };
        }
        
        [HttpGet]
        [Route("api/configuration/jurisdictions")]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
               = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var culture = _cultureResolver.Resolve();

            var countries = _dbContext.Set<Country>().AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
                countries = countries.Where(_ => _.Id.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1 || _.Name.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);

            var count = countries.Count();

            var executedResults = countries.OrderByProperty("Name",
                    extendedQueryParams.SortDir)
                    .Skip(extendedQueryParams.Skip.GetValueOrDefault())
                    .Take(extendedQueryParams.Take.GetValueOrDefault());

            var data = executedResults.Select(_ => new
                                         {
                                             Code = _.Id,
                                             Description = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                             ExactMatch =
                                                 _.Id.Equals(search, StringComparison.InvariantCultureIgnoreCase),
                                             CanEdit = false
                                         });

            return new PagedResults(data, count);
        }
        
    }
}